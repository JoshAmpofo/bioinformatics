#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"
VCF_DIR="results/vcf"
OUT_DIR="results/statistics/mutation_spectrum"

mkdir -p "$OUT_DIR"

SUMMARY="${OUT_DIR}/substitution_spectrum.tsv"

printf "sample\tgeneration\trun\tsubstitution\tcount\n" \
    > "$SUMMARY"


tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    VCF="${VCF_DIR}/${RUN}.PASS.norm.vcf.gz"

    echo "Processing $RUN..."

    bcftools query \
        -i 'TYPE="snp"' \
        -f '%REF\t%ALT\n' \
        "$VCF" |
    awk \
        -v sample="$SAMPLE" \
        -v generation="$GENERATION" \
        -v run="$RUN" '
        BEGIN {
            count["A>G"]=0
            count["A>C"]=0
            count["A>T"]=0
            count["C>T"]=0
            count["C>G"]=0
            count["C>A"]=0
        }

        {
            ref=$1
            alt=$2

            # Collapse reverse complements
            if (ref=="T") {
                ref="A"

                if (alt=="C") alt="G"
                else if (alt=="G") alt="C"
                else if (alt=="A") alt="T"
            }

            else if (ref=="G") {
                ref="C"

                if (alt=="A") alt="T"
                else if (alt=="C") alt="G"
                else if (alt=="T") alt="A"
            }

            type=ref ">" alt

            if (type in count)
                count[type]++
        }

        END {
            order[1]="A>G"
            order[2]="A>C"
            order[3]="A>T"
            order[4]="C>T"
            order[5]="C>G"
            order[6]="C>A"

            for (i=1; i<=6; i++) {

                type=order[i]

                print sample "\t" \
                      generation "\t" \
                      run "\t" \
                      type "\t" \
                      count[type]
            }
        }
        ' >> "$SUMMARY"

done

echo
column -t -s $'\t' "$SUMMARY"
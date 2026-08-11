#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"

ANN_DIR="results/annotation"
OUT_DIR="results/statistics/annotation"

mkdir -p "$OUT_DIR"

ALL="${OUT_DIR}/all_annotated_variants.tsv"

############################################################
# Combined header
############################################################

printf "sample\tgeneration\trun\tchrom\tposition\tref\talt\tqual\tallele\tconsequence\timpact\tgene\tgene_id\tfeature_type\tfeature_id\tbiotype\thgvs_c\thgvs_p\n" \
    > "$ALL"


############################################################
# Process samples
############################################################

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    echo "=============================================="
    echo "Extracting annotations: $RUN"
    echo "=============================================="

    VCF="${ANN_DIR}/${RUN}.annotated.vcf.gz"

    SAMPLE_OUT="${OUT_DIR}/${RUN}.annotated_variants.tsv"


    if [[ ! -s "$VCF" ]]; then
        echo "ERROR: Missing annotated VCF:"
        echo "$VCF"
        exit 1
    fi


    ########################################################
    # Header
    ########################################################

    printf "sample\tgeneration\trun\tchrom\tposition\tref\talt\tqual\tallele\tconsequence\timpact\tgene\tgene_id\tfeature_type\tfeature_id\tbiotype\thgvs_c\thgvs_p\n" \
        > "$SAMPLE_OUT"


    ########################################################
    # Extract ANN field
    #
    # SnpEff ANN order:
    #
    # 1  Allele
    # 2  Annotation / consequence
    # 3  Impact
    # 4  Gene name
    # 5  Gene ID
    # 6  Feature type
    # 7  Feature ID
    # 8  Transcript biotype
    # 9  Rank
    # 10 HGVS.c
    # 11 HGVS.p
    ########################################################

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%INFO/ANN\n' \
        "$VCF" |
    awk \
        -F '\t' \
        -v OFS='\t' \
        -v sample="$SAMPLE" \
        -v generation="$GENERATION" \
        -v run="$RUN" '

        {
            chrom=$1
            pos=$2
            ref=$3
            alt=$4
            qual=$5

            n=split($6, annotations, ",")

            for (i=1; i<=n; i++) {

                split(annotations[i], ann, "|")

                print sample,
                      generation,
                      run,
                      chrom,
                      pos,
                      ref,
                      alt,
                      qual,
                      ann[1],
                      ann[2],
                      ann[3],
                      ann[4],
                      ann[5],
                      ann[6],
                      ann[7],
                      ann[8],
                      ann[10],
                      ann[11]
            }
        }
        ' >> "$SAMPLE_OUT"


    ########################################################
    # Append without duplicate header
    ########################################################

    tail -n +2 "$SAMPLE_OUT" >> "$ALL"


    echo "[OK] $SAMPLE_OUT"

done


echo
echo "=============================================="
echo "Annotation extraction complete"
echo "=============================================="

echo
echo "Combined table:"
echo "$ALL"

echo
echo "Number of annotation records:"
tail -n +2 "$ALL" | wc -l
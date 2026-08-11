#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"
VCF_DIR="results/vcf"
STATS_DIR="results/statistics/variants"

SUMMARY="${STATS_DIR}/pass_variant_summary.tsv"

printf "sample\tgeneration\trun\tpass_variants\tsnps\tindels\tts_tv\n" \
    > "$SUMMARY"

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    echo "=============================================="
    echo "Preparing PASS variants for $RUN"
    echo "=============================================="

    INPUT="${VCF_DIR}/${RUN}.filtered.vcf.gz"
    PASS="${VCF_DIR}/${RUN}.PASS.vcf.gz"
    STATS="${STATS_DIR}/${RUN}.PASS.bcftools_stats.txt"

    ########################################################
    # Extract PASS records only
    ########################################################

    bcftools view \
        -f PASS \
        -Oz \
        -o "$PASS" \
        "$INPUT"

    bcftools index -t "$PASS"

    ########################################################
    # Normalize representation
    ########################################################

    NORMALIZED="${VCF_DIR}/${RUN}.PASS.norm.vcf.gz"

    bcftools norm \
        -f data/reference/ecoli_rel606.fasta \
        -m -any \
        -Oz \
        -o "$NORMALIZED" \
        "$PASS"

    bcftools index -t "$NORMALIZED"

    ########################################################
    # Statistics
    ########################################################

    bcftools stats "$NORMALIZED" > "$STATS"

    TOTAL=$(bcftools view -H "$NORMALIZED" | wc -l)

    SNPS=$(bcftools view \
        -v snps \
        -H "$NORMALIZED" |
        wc -l)

    INDELS=$(bcftools view \
        -v indels \
        -H "$NORMALIZED" |
        wc -l)

    TSTV=$(awk -F '\t' '
        $1=="TSTV" {
            print $5
            exit
        }
    ' "$STATS")

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$GENERATION" \
        "$RUN" \
        "$TOTAL" \
        "$SNPS" \
        "$INDELS" \
        "${TSTV:-NA}" \
        >> "$SUMMARY"

done

echo
column -t -s $'\t' "$SUMMARY"
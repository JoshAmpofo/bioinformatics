#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"

VCF_DIR="results/vcf"
OUT_DIR="results/annotation"
STATS_DIR="results/statistics/annotation"

SNPEFF_CONFIG="snpeff/snpEff.config"
GENOME="REL606"

mkdir -p "$OUT_DIR"
mkdir -p "$STATS_DIR"

echo "=============================================="
echo "LTEE Ara-3 variant annotation"
echo "Started: $(date)"
echo "=============================================="

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    echo
    echo "=============================================="
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "=============================================="

    INPUT="${VCF_DIR}/${RUN}.PASS.norm.vcf.gz"

    OUTPUT="${OUT_DIR}/${RUN}.annotated.vcf.gz"

    HTML="${STATS_DIR}/${RUN}.snpeff_summary.html"

    CSV="${STATS_DIR}/${RUN}.snpeff_stats.csv"


    if [[ ! -s "$INPUT" ]]; then

        echo "ERROR: Input VCF missing:"
        echo "$INPUT"

        exit 1

    fi


    if [[ -s "$OUTPUT" ]]; then

        echo "[SKIP] Annotation already exists:"
        echo "$OUTPUT"

        continue

    fi


    echo "Annotating variants..."

    snpEff \
        -c "$SNPEFF_CONFIG" \
        -v \
        -stats "$HTML" \
        -csvStats "$CSV" \
        "$GENOME" \
        "$INPUT" |
    bgzip -c \
        > "$OUTPUT"


    tabix \
        -p vcf \
        "$OUTPUT"


    echo "[OK] Annotated $RUN"

done

echo
echo "=============================================="
echo "Annotation complete"
echo "Finished: $(date)"
echo "=============================================="
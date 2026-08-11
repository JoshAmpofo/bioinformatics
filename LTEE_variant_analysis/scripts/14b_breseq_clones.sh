#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"

REF="snpeff/data/REL606/genes.gbk"

TRIM_DIR="data/trimmed"
UNPAIRED_DIR="${TRIM_DIR}/unpaired"

OUT_DIR="results/breseq_consensus"
GD_DIR="results/gd_consensus"

THREADS=4

mkdir -p "$OUT_DIR"
mkdir -p "$GD_DIR"

echo "=============================================="
echo "breseq consensus analysis of Ara-3 clones"
echo "Started: $(date)"
echo "=============================================="

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN RAW_R1 RAW_R2
do

    echo
    echo "----------------------------------------------"
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "----------------------------------------------"

    R1="${TRIM_DIR}/${RUN}_1.trim.fastq.gz"
    R2="${TRIM_DIR}/${RUN}_2.trim.fastq.gz"

    U1="${UNPAIRED_DIR}/${RUN}_1.unpaired.fastq.gz"
    U2="${UNPAIRED_DIR}/${RUN}_2.unpaired.fastq.gz"

    SAMPLE_OUT="${OUT_DIR}/${RUN}"

    READS=("$R1" "$R2")

    [[ -s "$U1" ]] && READS+=("$U1")
    [[ -s "$U2" ]] && READS+=("$U2")

    if [[ -s "${SAMPLE_OUT}/output/output.gd" ]]
    then
        echo "[SKIP] Existing result for $RUN"
    else

        breseq \
            -j "$THREADS" \
            -n "$SAMPLE" \
            -r "$REF" \
            -o "$SAMPLE_OUT" \
            "${READS[@]}"

    fi

    cp \
        "${SAMPLE_OUT}/output/output.gd" \
        "${GD_DIR}/${RUN}.gd"

done

echo
echo "breseq consensus analysis complete."
#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"

REF="snpeff/data/REL606/genes.gbk"

TRIM_DIR="data/trimmed"
UNPAIRED_DIR="${TRIM_DIR}/unpaired"

OUT_DIR="results/breseq"
GD_DIR="results/gd"

THREADS=4

mkdir -p "$OUT_DIR"
mkdir -p "$GD_DIR"

echo "=============================================="
echo "breseq population/structural analysis"
echo "Started: $(date)"
echo "Reference: $REF"
echo "=============================================="


if [[ ! -s "$REF" ]]; then
    echo "ERROR: GenBank reference missing:"
    echo "$REF"
    exit 1
fi


tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN RAW_R1 RAW_R2
do

    echo
    echo "=============================================="
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "=============================================="

    R1="${TRIM_DIR}/${RUN}_1.trim.fastq.gz"
    R2="${TRIM_DIR}/${RUN}_2.trim.fastq.gz"

    U1="${UNPAIRED_DIR}/${RUN}_1.unpaired.fastq.gz"
    U2="${UNPAIRED_DIR}/${RUN}_2.unpaired.fastq.gz"

    SAMPLE_OUT="${OUT_DIR}/${RUN}"

    GD="${SAMPLE_OUT}/output/output.gd"


    if [[ -s "$GD" ]]; then

        echo "[SKIP] Existing breseq result:"
        echo "$GD"

    else

        READS=("$R1" "$R2")

        # Include surviving orphan reads as well.
        # breseq maps short reads independently, so these still
        # contain useful information.

        if [[ -s "$U1" ]]; then
            READS+=("$U1")
        fi

        if [[ -s "$U2" ]]; then
            READS+=("$U2")
        fi


        breseq \
            -j "$THREADS" \
            -p \
            -n "$SAMPLE" \
            -r "$REF" \
            -o "$SAMPLE_OUT" \
            "${READS[@]}"

    fi


    if [[ ! -s "$GD" ]]; then
        echo "ERROR: breseq did not produce:"
        echo "$GD"
        exit 1
    fi


    cp "$GD" "${GD_DIR}/${RUN}.gd"

    echo "[OK] $RUN"

done


echo
echo "=============================================="
echo "breseq runs complete"
echo "Finished: $(date)"
echo "=============================================="
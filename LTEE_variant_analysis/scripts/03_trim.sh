#!/usr/bin/env bash

set -euo pipefail

METADATA="metadata/samples.tsv"

TRIM_DIR="data/trimmed"
UNPAIRED_DIR="${TRIM_DIR}/unpaired"
STATS_DIR="results/statistics/trimming"

THREADS=4

mkdir -p "$TRIM_DIR"
mkdir -p "$UNPAIRED_DIR"
mkdir -p "$STATS_DIR"

echo "=============================================="
echo "LTEE Ara-3 read trimming"
echo "Started: $(date)"
echo "=============================================="

############################################################
# Locate the Nextera adapter file installed with Trimmomatic
############################################################

ADAPTERS=$(find "$CONDA_PREFIX" \
    -type f \
    -name "NexteraPE-PE.fa" \
    2>/dev/null | head -n 1)

if [[ -z "${ADAPTERS}" ]]; then
    echo "ERROR: NexteraPE-PE.fa could not be found."
    echo "Check your Trimmomatic installation."
    exit 1
fi

echo "Using adapter file:"
echo "$ADAPTERS"
echo


############################################################
# Process each paired-end sample
############################################################

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    echo "----------------------------------------------"
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "----------------------------------------------"

    OUT_R1="${TRIM_DIR}/${RUN}_1.trim.fastq.gz"
    OUT_R2="${TRIM_DIR}/${RUN}_2.trim.fastq.gz"

    OUT_U1="${UNPAIRED_DIR}/${RUN}_1.unpaired.fastq.gz"
    OUT_U2="${UNPAIRED_DIR}/${RUN}_2.unpaired.fastq.gz"

    SUMMARY="${STATS_DIR}/${RUN}.trimmomatic_summary.txt"

    ########################################################
    # Skip if paired outputs already exist
    ########################################################

    if [[ -s "$OUT_R1" && -s "$OUT_R2" ]]; then

        echo "[SKIP] Trimmed paired reads already exist for $RUN"

    else

        trimmomatic PE \
            -threads "$THREADS" \
            -phred33 \
            -summary "$SUMMARY" \
            "$R1" \
            "$R2" \
            "$OUT_R1" \
            "$OUT_U1" \
            "$OUT_R2" \
            "$OUT_U2" \
            ILLUMINACLIP:"${ADAPTERS}":2:40:15 \
            SLIDINGWINDOW:4:20 \
            MINLEN:25

    fi

    echo

done


############################################################
# Check compressed FASTQ integrity
############################################################

echo "Checking trimmed FASTQ integrity..."

for FILE in "$TRIM_DIR"/*.trim.fastq.gz
do

    gzip -t "$FILE"

    echo "[OK] $FILE"

done


############################################################
# Generate SeqKit statistics
############################################################

echo
echo "Generating trimmed-read statistics..."

seqkit stats \
    "$TRIM_DIR"/*.trim.fastq.gz \
    > "$STATS_DIR/trimmed_seqkit_stats.txt"


echo
echo "=============================================="
echo "Trimming complete"
echo "Finished: $(date)"
echo
echo "Paired reads:"
echo "$TRIM_DIR"
echo
echo "Statistics:"
echo "$STATS_DIR"
echo "=============================================="
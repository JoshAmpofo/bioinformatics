#!/usr/bin/env bash

set -euo pipefail

TRIM_DIR="data/trimmed"
FASTQC_DIR="results/fastqc_trimmed"
MULTIQC_DIR="results/multiqc/trimmed"

THREADS=4

mkdir -p "$FASTQC_DIR"
mkdir -p "$MULTIQC_DIR"

echo "=============================================="
echo "Post-trimming quality control"
echo "Started: $(date)"
echo "=============================================="

fastqc \
    --threads "$THREADS" \
    --outdir "$FASTQC_DIR" \
    "$TRIM_DIR"/*.trim.fastq.gz


echo
echo "Running MultiQC..."

multiqc \
    "$FASTQC_DIR" \
    --outdir "$MULTIQC_DIR" \
    --force


echo
echo "=============================================="
echo "Post-trimming QC complete"
echo "Finished: $(date)"
echo
echo "MultiQC report:"
echo "$MULTIQC_DIR/multiqc_report.html"
echo "=============================================="
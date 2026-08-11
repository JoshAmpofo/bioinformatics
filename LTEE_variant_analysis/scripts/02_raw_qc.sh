#!/usr/bin/env bash

set -euo pipefail

RAW_DIR="data/raw"
FASTQC_DIR="results/fastqc_raw"
MULTIQC_DIR="results/multiqc/raw"

THREADS=4

mkdir -p "$FASTQC_DIR"
mkdir -p "$MULTIQC_DIR"

echo "=========================================="
echo "Raw FASTQ quality control"
echo "Started: $(date)"
echo "=========================================="

fastqc \
    --threads "$THREADS" \
    --outdir "$FASTQC_DIR" \
    "$RAW_DIR"/*.fastq.gz

echo
echo "Running MultiQC..."

multiqc \
    "$FASTQC_DIR" \
    --outdir "$MULTIQC_DIR" \
    --force

echo
echo "=========================================="
echo "Raw-read QC complete"
echo "Finished: $(date)"
echo
echo "MultiQC report:"
echo "$MULTIQC_DIR/multiqc_report.html"
echo "=========================================="
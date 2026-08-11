#!/usr/bin/env bash

set -euo pipefail

RAW_DIR="data/raw"

mkdir -p "$RAW_DIR"

echo "=========================================="
echo "Downloading LTEE Ara-3 sequencing reads"
echo "Started: $(date)"
echo "=========================================="

download_file () {

    URL="$1"
    OUTPUT="$2"

    if [[ -s "$OUTPUT" ]]; then
        echo "[SKIP] $OUTPUT already exists."
    else
        echo "[DOWNLOAD] $OUTPUT"

        curl \
            --fail \
            --location \
            --retry 5 \
            --retry-delay 5 \
            --output "$OUTPUT" \
            "$URL"
    fi
}


download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_1.fastq.gz" \
"$RAW_DIR/SRR2589044_1.fastq.gz"

download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_2.fastq.gz" \
"$RAW_DIR/SRR2589044_2.fastq.gz"


download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz" \
"$RAW_DIR/SRR2584863_1.fastq.gz"

download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz" \
"$RAW_DIR/SRR2584863_2.fastq.gz"


download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_1.fastq.gz" \
"$RAW_DIR/SRR2584866_1.fastq.gz"

download_file \
"https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_2.fastq.gz" \
"$RAW_DIR/SRR2584866_2.fastq.gz"


echo
echo "=========================================="
echo "Download complete"
echo "Finished: $(date)"
echo "=========================================="

ls -lh "$RAW_DIR"
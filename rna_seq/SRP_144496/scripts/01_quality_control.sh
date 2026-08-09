#!/usr/bin/env bash

set -euo pipefail

# ==================================================================
# SRP144496 RNA-seq Quality Assessment
# Stage 1: Quality Control - FASTQ validation/recovery + raw_read QC
# ===================================================================

# ----------------------------------------
# Configuration
# ----------------------------------------


METADATA="metadata/SRP144496_metadata.tsv"
RAW_DIR="raw_data"
FASTQC_DIR="results/01_raw_fastqc"
MULTIQC_DIR="results/02_raw_multiqc"

THREADS=4
MAX_DOWNLOAD_ATTEMPTS=3

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/01_quality_control.log"

# -------------------------------
# Setup
# --------------------------------

mkdir -p "$RAW_DIR"
mkdir -p "$FASTQC_DIR"
mkdir -p "$MULTIQC_DIR"
mkdir -p "$LOG_DIR"

# send stdout and stderr to screen + logfile
exec > >(tee -a "$LOG_FILE") 2>&1


echo "==========================================="
echo "SRP144496 RNA-seq Quality Assessment"
echo "==========================================="
echo "Started: $(date)"
echo

# -------------------------
# Function: fail cleanly
# -------------------------

die() {
    echo
    echo "ERROR: $1"
    echo "Pipeline stopped."
    exit 1
}

# --------------------------
# Check dependencies
# --------------------------

echo "[1/5] Checking required software..."

for PROGRAM in awk wget gzip stat fastqc multiqc
do
    if ! command -v "$PROGRAM" >/dev/null 2>&1
    then
        die "Required program $PROGRAM not found in PATH. Please install it and try again."
    fi
done

echo "All required programs are available."
echo

# --------------------------
# Check metadata
# --------------------------

echo "[2/5] Checking metadata..."

if [[ ! -s "$METADATA" ]]
then
    die "Metadata file not found or empty: $METADATA"
fi

# Ensure required columns exist
HEADER=$(head -1 "$METADATA")
REQUIRED_COLUMNS=("run_accession" "fastq_ftp" "fastq_bytes")

for COLUMN in REQUIRED_COLUMNS
do
    if ! echo "$HEADER" | tr '\t' '\n' | grep -qx "$COLUMN"
    then
        die "Metadata is missing required column: $COLUMN"
    fi
done

echo "Metadata file looks valid."
echo

# ===============================================
# Function:download one FASTQ
# ===============================================

download_fastq() {
    local run="$1"
    local url="$2"
    local destination="$3"

    # ENA gives URLS without protocol
    if [[ "$url" != http://* && "$url" != https://* && "$url" != ftp://* ]]
    then
        url="https://${url}"
    fi

    echo "Downloading $run..."

    # Remove potentially corrupted partial file first
    rm -f "$destination"

    for ((attempt=1; attempt<=MAX_DOWNLOAD_ATTEMPTS; attempt++))
    do
        echo "Download attempt $attempt/$MAX_DOWNLOAD_ATTEMPTS"

        if wget \
            --tries=5 \
            --timeout=60 \
            --continue \
            --output-document="$destination" \
            "$url"
        then
            echo "Download command completed."
            return 0
        fi

        echo "Download attempt $attempt failed."

        # Delete bad partial file before next attempt
        rm -f "$destination"

        sleep 3

    done

    return 1

}

# =======================================
# Function: validate one FASTQ file
# =======================================

validate_fastq() {
    local file="$1"
    local expected_size="$2"

    # check existence
    if [[ ! -f "$file" ]]
    then
        echo "FAIL: FASTQ file not found: $file"
        return 1
    fi

    # check it isn't empty
    if [[ ! -s "$file" ]]
    then
        echo "FAIL: FASTQ file is empty: $file"
        return 1
    fi

    # check expected byte size
    local actual_size

    actual_size=$(stat -c%s "$file")

    if [[ "$actual_size" -ne "$expected_size" ]]
    then
        echo "FAIL: File-size mismatch. Expected: $expected_size bytes, Actual: $actual_size bytes for file: $file"
        return 1
    fi

    # check gzip CRC/integruty
    if ! gzip -t "$file" 2>/dev/null
    then
        echo "FAIL: gzip integrity test failed for file: $file"
        return 1
    fi

    echo "PASS: FASTQ file validated successfully: $file"
    return 0
}

# ==========================================
# Validate / recover all FASTQs
# ==========================================

echo "[3/5] Validating and recovering FASTQ files..."
echo

FAILED_FILES=0
RECOVERED_FILES=0
TOTAL_FILES=0

# determine metadata coulmn positions dynamically
RUN_COL=$(head -1 "$METADATA" | tr '\t' '\n' | nl -ba | awk '$2=="run_accession"{print $1}')
FTP_COL=$(head -1 "$METADATA" | tr '\t' '\n' | nl -ba | awk '$2=="fastq_ftp"{print $1}')
BYTE_COL=$(head -1 "$METADATA" | tr '\t' '\n' | nl -ba | awk '$2=="fastq_bytes"{print $1}')

while IFS=$'\t' read -r RUN URL EXPECTED_SIZE
do
    TOTAL_FILES=$((TOTAL_FILES + 1))
    FASTQ="${RAW_DIR}/${RUN}.fastq.gz"

    echo "------------------------------------------------------------"
    echo "Sample: $RUN"
    echo "File: $FASTQ"

    if validate_fastq "$FASTQ" "$EXPECTED_SIZE"
    then
        echo "No action required."
        continue
    fi

    echo
    echo "Attempting automatic recovery..."

    if ! download_fastq "$RUN" "$URL" "$FASTQ"
    then
        echo "ERROR: Could not download $RUN."
        FAILED_FILES=$((FAILED_FILES+ 1))
        continue
    fi

    echo
    echo "Validating replacement..."

    if validate_fastq "$FASTQ" "$EXPECTED_SIZE"
    then
        echo "RECOVERED: $RUN"
        RECOVERED_FILES=$((RECOVERED_FILES + 1))
    else
        echo "ERROR: Replacement file is still invalid."
        FAILED_FILES=$((FAILED_FILES + 1))

        # remove any known corrupt FASTQ download
        rm -f "$FASTQ"
    fi

done < <(
    awk \
        -F'\t' \
        -v r="$RUN_COL" \
        -v f="$FTP_COL" \
        -v b="$BYTE_COL" \
        'NR>1 {print $r "\t" $f "\t" $b}' \
        "$METADATA"
)

echo
echo "========================================================="
echo "FASTQ validation summary"
echo "========================================================="
echo "Expected files:   $TOTAL_FILES"
echo "Recovered files:  $RECOVERED_FILES"
echo "FAiled files:     $FAILED_FILES"
echo

# --------------------------
# Stop if anything failed
# --------------------------

if [[ "$FAILED_FILES" -gt 0 ]]
then
    die "$FAILED_FILES FASTQ file(s) could not be validated."
fi

echo "ALL FASTQ files are valid."
echo

# ==============================================
# FASTQC
# ==============================================

echo "[4/5] Running FastQC..."

fastqc \
    --threads "$THREADS" \
    --outdir "$FASTQC_DIR" \
    "$RAW_DIR"/*.fastq.gz

echo
echo "FastQC completed."
echo

# ==============================================
# MultiQC
# ==============================================

echo "[5/5] Running MultiQC..."

multiqc \
    "$FASTQC_DIR"
    --outdir "$MULTIQC_DIR" \
    --filename SRP144496_raw_multiqc.html \
    --force

echo
echo "================================================="
echo "QUALITY ASSESSMENT COMPLETED SUCESSFULLY"
echo "================================================="
echo
echo "FASTQ files checked: $TOTAL_FILES"
echo "FASTQ files recovered: $RECOVERED_FILES"
echo
echo "FastQC results:"
echo "  $FASTQC_DIR"
echo
echo "MultiQC report:"
echo "  $MULTIQC_DIR/SRP144496_raw_multiqc.html"
echo
echo "Log:"
echo "  $LOG_FILE"
echo
echo "Pipeline finished: $(date)"    




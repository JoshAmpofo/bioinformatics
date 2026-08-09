#!/usr/bin/env bash

set -euo pipefail

# ======================================================
# SRP144496 RNA-seq
# Stage 2: GRCh38 + HISAT2 alignment
# ======================================================

THREADS="${THREADS:-8}"
MIN_AVAILABLE_GB=7

GENCODE_VERSION="50"

RAW_DIR="raw_data"
REF_DIR="reference_genome/gencode_v${GENCODE_VERSION}"
INDEX_DIR="${REF_DIR}/hisat2_index"

ALIGN_DIR="results/03_alignment"
MULTIQC_DIR="results/04_alignment_multiqc"
LOG_DIR="logs"

GENOME_GZ="${REF_DIR}/GRCh38.primary_assembly.genome.fa.gz"
GENOME="${REF_DIR}/GRCh38.primary_assembly.genome.fa"

GTF_GZ="${REF_DIR}/gencode.v${GENCODE_VERSION}.primary_assembly.annotation.gtf.gz"
GTF="${REF_DIR}/gencode.v${GENCODE_VERSION}.primary_assembly.annotation.gtf"

SPLICE_SITES="${REF_DIR}/gencode.v${GENCODE_VERSION}.splicesites.txt"

INDEX_PREFIX="${INDEX_DIR}/GRCh38"

GENOME_URL="https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_${GENCODE_VERSION}/GRCh38.primary_assembly.genome.fa.gz"

GTF_URL="https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_${GENCODE_VERSION}/gencode.v${GENCODE_VERSION}.primary_assembly.annotation.gtf.gz"


mkdir -p \
    "$REF_DIR" \
    "$INDEX_DIR" \
    "$ALIGN_DIR" \
    "$MULTIQC_DIR" \
    "$LOG_DIR"

LOG_FILE="${LOG_DIR}/02_alignment.log"

exec > >(tee -a "$LOG_FILE") 2>&1

die () {
    echo
    echo "ERROR: $1"
    echo "Pipeline stopped."
    exit 1
}


echo "==================================================="
echo "SRP144496 RNA-seq Alignment"
echo "HISAT2 + GRCh38 + GENCODE v${GENCODE_VERSION}"
echo "==================================================" 


# ========================================================-
# Dependency checks
# ========================================================
echo "[1/8] Checking software..."

for PROGRAM in \
    hisat2 \
    hisat2-build \
    hisat2_extract_splice_sites.py \
    samtools \
    wget \
    gzip \
    awk \
    multiqc
do
    command -v "$PROGRAM" >/dev/null 2>&1 ||
        die "'$PROGRAM' was not found."
done

echo "Software checks passed."
echo


# ========================================================
# 2. Memory check
# ========================================================
echo "[2/8] Checking available memory..."

AVAILABLE_KB=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)

AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))

echo "Available RAM: approximately ${AVAILABLE_GB} GiB"

if [[ "$AVAILABLE_GB" -lt "$MIN_AVAILABLE_GB" ]]
then
    die "Only ${AVAILABLE_GB} GiB RAM available.
    Close memory-intensive applications and rerun script."
fi

echo "Memory check passed."
echo


# ========================================================
# 3. Validate FASTQs
# ========================================================
echo "[3/8] Checking FASTQinput..."

FASTQ_COUNT=$(find "$RAW_DIR" \
    -maxdepth 1 \
    -type f \
    -name "*.fastq.gz" | wc -l
)

if [[ "$FASTQ_COUNT" -eq 0 ]]
then
    die "No FASTQ files found."
fi

echo "Found $FASTQ_COUNT FASTQ files."

for FASTQ in "$RAW_DIR"/*.fastq.gz
do
    echo "Checking $(basename "$FASTQ")..."
    gzip -t "$FASTQ" 2>/dev/null ||
        die "Corrupt FASTQ detected: $FASTQ"
done

echo "All FASTQs passed validation."
echo


# ========================================================
# 4. Download reference genome
# =======================================================
echo "[4/8] Preparing GRCh38..."

if [[ ! -s "$GENOME" ]]
then

    if [[ ! -s "$GENOME_GZ" ]]
    then
        echo "Downloading GRCh38..."
        wget \
            --tries=5 \
            --timeout=60 \
            -O "$GENOME_GZ" \
            "$GENOME_URL"
    fi

    gzip -t "$GENOME_GZ" ||
        die "Genome archive is corrupted."
    
    echo "Decompressing genome..."
    gzip -dc "$GENOME_GZ" > "$GENOME"
fi

[[ -s "$GENOME" ]] ||
    die "Reference genome preparation failed."

echo "Genome ready."
echo


# =======================================================
# 5. Download GTF + extract splice rates
# =======================================================
echo "[5/8] Preparing annotation..."

if [[ ! -s "$GTF" ]]
then

    if [[ ! -s "$GTF_GZ" ]]
    then
        echo "Downloading GENCODE v${GENCODE_VERSION} GTF annotation..."
        wget \
            --tries=5 \
            --timeout=60 \
            -O "$GTF_GZ" \
            "$GTF_URL"
    fi

    gzip -t "$GTF_GZ" ||
        die "GTF Annotation archive is corrupted."
    
    echo "Decompressing GTF..."
    gzip -dc "$GTF_GZ" > "$GTF"
fi

if [[ ! -s "$SPLICE_SITES" ]]
then
    echo "Extracting known splice sites..."

    hisat2_extract_splice_sites.py \
        "$GTF" \
        > "$SPLICE_SITES"
fi

echo "Annotation ready."
echo

# =======================================
# 6. Build HISAT2 index
# =======================================
echo "[6/8] Checking HISAT2 index..."

index_complete() {
    local extension="$1"
    local i

    for i in {1..8}
    do
        [[ -s "${INDEX_PREFIX}.${i}.${extension}" ]] || return 1
    done
}

if ! index_complete "ht2" && ! index_complete "ht2l"
then
    echo "Complete index not found."
    echo "Building GRCh38 HISAT2 index..."
    echo "This may take some time."

    rm -f "${INDEX_PREFIX}".*.ht2
    rm -f "${INDEX_PREFIX}".*.ht2l

    hisat2-build \
        -p "$THREADS" \
        "$GENOME" \
        "$INDEX_PREFIX"
else
    echo "Complete existing HISAT2 index found."
    echo "Skipping index construction."
fi


# =======================================
# 7. Align all samples with HISAT2
# =======================================
echo "[7/8] Aligning samples..."

FAILED=0
ALIGNED=0
SKIPPED=0

for FASTQ in "$RAW_DIR"/*.fastq.gz
do
    RUN=$(basename "$FASTQ" .fastq.gz)
    SAMPLE_DIR="${ALIGN_DIR}/${RUN}"

    mkdir -p "$SAMPLE_DIR"

    BAM="${SAMPLE_DIR}/${RUN}.sorted.bam"
    SUMMARY="${SAMPLE_DIR}/${RUN}_hisat2_summary.txt"
    FLAGSTAT="${SAMPLE_DIR}/${RUN}_flagstat.txt"

    echo
    echo "---------------------------------------------------"
    echo "Sample: $RUN"
    echo "---------------------------------------------------"

    # resume support
    if [[ -s "$BAM" ]] && samtools quickcheck "$BAM"
    then
        echo "Valid existing BAM detected."
        echo "Skipping alignment."

        SKIPPED=$((SKIPPED + 1))
    
    else
        rm -f "$BAM"

        echo "Running HISAT2..."

        if hisat2 \
            -p "$THREADS" \
            -x "$INDEX_PREFIX" \
            -U "$FASTQ" \
            --known-splicesite-infile "$SPLICE_SITES" \
            --summary-file "$SUMMARY" \
            --new-summary \
            2>> "$SUMMARY" \
            | samtools sort \
                -@ 2 \
                -o "$BAM" \
                -
        then
            echo "Alignment completed successfully."
        else
            echo "ERROR: Alignment failed for $RUN"
            rm -f "$BAM"
            FAILED=$((FAILED +1))
            continue
        fi

        # BAM validation
        if ! samtools quickcheck "$BAM"
        then
            echo "ERROR: BAM validation failed."
            rm -f "$BAM"
            FAILED=$((FAILED + 1))
            continue
        fi

        ALIGNED=$((ALIGNED + 1))
    fi

    # BAM Index
    if [[ ! -s "${BAM}.bai" ]]
    then
        echo "Indexing BAM..."

        samtools index \
            -@ 2 \
            "$BAM"
    fi

    # Mapping statistics
    echo "generating flagstat..."

    samtools flagstat \
        -@ 2 \
        "$BAM" \
        > "$FLAGSTAT"
done


echo
echo "Alignment summary"
echo "---------------------------------------------------"
echo "New alignments:   $ALIGNED"
echo "Skipped:          $SKIPPED"
echo "Failed:           $FAILED"
echo

if [[ "$FAILED" -gt 0 ]]
then
    die "$FAILED sample(s) failed alignment."
fi


# ========================================
# 8. MultiQC
# ========================================

echo "[8/8] Running MultiQC..."

multiqc \
    "$ALIGN_DIR" \
    --outdir "$MULTIQC_DIR" \
    --filename "SRP144496_alignment_multiqc_report.html" \
    --force


echo
echo "=========================================================="
echo "SRP144496 RNA-seq Alignment completed successfully."
echo "=========================================================="
echo
echo "BAM files:"
echo "  $ALIGN_DIR"
echo
echo "MultiQC report:"
echo "  $MULTIQC_DIR/SRP144496_alignment_multiqc_report.html"
echo
echo "Reference genome:"
echo "  $GENOME"
echo
echo "GTF annotation:"
echo "  $GTF"
echo
echo "Log:"
echo "  $LOG_FILE"
echo
echo "Finished: $(date)"

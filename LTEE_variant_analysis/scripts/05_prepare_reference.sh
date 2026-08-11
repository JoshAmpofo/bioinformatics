#!/usr/bin/env bash

set -euo pipefail

REF_DIR="data/reference"

REF_GZ="${REF_DIR}/ecoli_rel606.fasta.gz"
REF="${REF_DIR}/ecoli_rel606.fasta"

REF_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz"

mkdir -p "$REF_DIR"
mkdir -p results/statistics/reference

echo "=============================================="
echo "Preparing E. coli REL606 reference genome"
echo "Started: $(date)"
echo "=============================================="

############################################################
# 1. Download reference
############################################################

if [[ -s "$REF" ]]; then

    echo "[SKIP] Uncompressed reference already exists:"
    echo "$REF"

elif [[ -s "$REF_GZ" ]]; then

    echo "[FOUND] Compressed reference already exists."

else

    echo "[DOWNLOAD] REL606 reference genome"

    curl \
        --fail \
        --location \
        --retry 5 \
        --retry-delay 5 \
        --output "$REF_GZ" \
        "$REF_URL"

fi


############################################################
# 2. Test compressed file
############################################################

if [[ -s "$REF_GZ" ]]; then

    echo
    echo "Testing gzip integrity..."

    gzip -t "$REF_GZ"

    echo "[OK] Reference archive passed gzip check."

fi


############################################################
# 3. Uncompress
############################################################

if [[ ! -s "$REF" ]]; then

    echo
    echo "Uncompressing reference..."

    gunzip "$REF_GZ"

fi


############################################################
# 4. Inspect reference
############################################################

echo
echo "Reference sequence header:"

grep "^>" "$REF"


############################################################
# 5. Basic reference statistics
############################################################

echo
echo "Calculating reference statistics..."

seqkit stats "$REF" \
    > results/statistics/reference/REL606_seqkit_stats.txt

cat results/statistics/reference/REL606_seqkit_stats.txt


############################################################
# 6. BWA index
############################################################

if [[ ! -f "${REF}.bwt" ]]; then

    echo
    echo "Building BWA index..."

    bwa index "$REF"

else

    echo
    echo "[SKIP] BWA index already present."

fi


############################################################
# 7. samtools FASTA index
############################################################

if [[ ! -f "${REF}.fai" ]]; then

    echo
    echo "Building samtools FASTA index..."

    samtools faidx "$REF"

else

    echo
    echo "[SKIP] samtools FASTA index already present."

fi


############################################################
# 8. Final check
############################################################

echo
echo "Reference directory:"
ls -lh "$REF_DIR"

echo
echo "=============================================="
echo "Reference preparation complete"
echo "Finished: $(date)"
echo "=============================================="
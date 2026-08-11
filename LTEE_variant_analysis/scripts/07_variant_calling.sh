#!/usr/bin/env bash

set -euo pipefail

############################################################
# Configuration
############################################################

METADATA="metadata/samples.tsv"

REF="data/reference/ecoli_rel606.fasta"

BAM_DIR="results/bam"
BCF_DIR="results/bcf"
VCF_DIR="results/vcf"
STATS_DIR="results/statistics/variants"

THREADS=4

mkdir -p "$BCF_DIR"
mkdir -p "$VCF_DIR"
mkdir -p "$STATS_DIR"


echo "=============================================="
echo "LTEE Ara-3 short-variant calling"
echo "Started: $(date)"
echo "=============================================="


############################################################
# Summary table
############################################################

SUMMARY="${STATS_DIR}/variant_counts.tsv"

printf "sample\tgeneration\trun\traw_variants\tfiltered_variants\n" \
    > "$SUMMARY"


############################################################
# Process samples
############################################################

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN R1 R2
do

    echo
    echo "=============================================="
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "=============================================="


    BAM="${BAM_DIR}/${RUN}.aligned.sorted.bam"

    RAW_BCF="${BCF_DIR}/${RUN}.raw.bcf"

    RAW_VCF="${VCF_DIR}/${RUN}.raw.vcf.gz"

    FILTERED_VCF="${VCF_DIR}/${RUN}.filtered.vcf.gz"


    ########################################################
    # Check BAM
    ########################################################

    if [[ ! -s "$BAM" ]]; then

        echo "ERROR: BAM not found:"
        echo "$BAM"

        exit 1

    fi


    ########################################################
    # 1. Generate genotype likelihoods
    ########################################################

    if [[ ! -s "$RAW_BCF" ]]; then

        echo "Running bcftools mpileup..."

        bcftools mpileup \
            --threads "$THREADS" \
            -Ou \
            -f "$REF" \
            -a FORMAT/AD,FORMAT/DP \
            "$BAM" \
        | bcftools view \
            -Ob \
            -o "$RAW_BCF"

    else

        echo "[SKIP] Existing BCF: $RAW_BCF"

    fi


    ########################################################
    # 2. Haploid variant calling
    ########################################################

    if [[ ! -s "$RAW_VCF" ]]; then

        echo "Calling haploid variants..."

        bcftools call \
            --threads "$THREADS" \
            --ploidy 1 \
            -m \
            -v \
            -Oz \
            -o "$RAW_VCF" \
            "$RAW_BCF"

        bcftools index -t "$RAW_VCF"

    else

        echo "[SKIP] Existing raw VCF: $RAW_VCF"

    fi


    ########################################################
    # 3. Quality filtering
    ########################################################

    if [[ ! -s "$FILTERED_VCF" ]]; then

        echo "Filtering variants..."

        bcftools filter \
            --threads "$THREADS" \
            -e 'QUAL<20 || FORMAT/DP<10' \
            -s LowQual \
            -Oz \
            -o "$FILTERED_VCF" \
            "$RAW_VCF"

        bcftools index -t "$FILTERED_VCF"

    else

        echo "[SKIP] Existing filtered VCF: $FILTERED_VCF"

    fi


    ########################################################
    # 4. Count variants
    ########################################################

    RAW_COUNT=$(bcftools view \
        -H "$RAW_VCF" |
        wc -l)

    PASS_COUNT=$(bcftools view \
        -f PASS \
        -H "$FILTERED_VCF" |
        wc -l)


    ########################################################
    # 5. bcftools stats
    ########################################################

    bcftools stats \
        "$FILTERED_VCF" \
        > "${STATS_DIR}/${RUN}.bcftools_stats.txt"


    ########################################################
    # 6. Variant type counts
    ########################################################

    SNP_COUNT=$(bcftools view \
        -f PASS \
        -v snps \
        -H "$FILTERED_VCF" |
        wc -l)

    INDEL_COUNT=$(bcftools view \
        -f PASS \
        -v indels \
        -H "$FILTERED_VCF" |
        wc -l)


    echo
    echo "Raw variants:      $RAW_COUNT"
    echo "PASS variants:     $PASS_COUNT"
    echo "PASS SNPs:         $SNP_COUNT"
    echo "PASS indels:       $INDEL_COUNT"


    ########################################################
    # Append summary
    ########################################################

    printf "%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$GENERATION" \
        "$RUN" \
        "$RAW_COUNT" \
        "$PASS_COUNT" \
        >> "$SUMMARY"


done


echo
echo "=============================================="
echo "Variant calling completed"
echo "Finished: $(date)"
echo "=============================================="

column -t -s $'\t' "$SUMMARY"
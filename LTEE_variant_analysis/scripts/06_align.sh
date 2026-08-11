#!/usr/bin/env bash

set -euo pipefail

############################################################
# Configuration
############################################################

METADATA="metadata/samples.tsv"

REF="data/reference/ecoli_rel606.fasta"

TRIM_DIR="data/trimmed"

BAM_DIR="results/bam"

QC_DIR="results/statistics/alignment"

THREADS=4

mkdir -p "$BAM_DIR"
mkdir -p "$QC_DIR"


############################################################
# Check required files
############################################################

if [[ ! -s "$REF" ]]; then
    echo "ERROR: Reference genome not found:"
    echo "$REF"
    exit 1
fi

if [[ ! -s "${REF}.fai" ]]; then
    echo "ERROR: samtools reference index missing:"
    echo "${REF}.fai"
    exit 1
fi


############################################################
# Get genome size automatically from FASTA index
############################################################

GENOME_SIZE=$(awk '{sum += $2} END {print sum}' "${REF}.fai")

echo "=============================================="
echo "LTEE Ara-3 alignment"
echo "Started: $(date)"
echo
echo "Reference:   $REF"
echo "Genome size: $GENOME_SIZE bp"
echo "Threads:     $THREADS"
echo "=============================================="
echo


############################################################
# Combined summary table
############################################################

SUMMARY="${QC_DIR}/alignment_summary.tsv"

printf "sample\tgeneration\trun\ttotal_reads\tmapped_reads\tmapping_percent\tproperly_paired\tproperly_paired_percent\tmean_depth\tbreadth_1x_percent\tbreadth_10x_percent\n" \
    > "$SUMMARY"


############################################################
# Process samples
############################################################

tail -n +2 "$METADATA" |
while IFS=$'\t' read -r SAMPLE GENERATION RUN RAW_R1 RAW_R2
do

    echo "=============================================="
    echo "Sample:     $SAMPLE"
    echo "Generation: $GENERATION"
    echo "Run:        $RUN"
    echo "=============================================="

    R1="${TRIM_DIR}/${RUN}_1.trim.fastq.gz"
    R2="${TRIM_DIR}/${RUN}_2.trim.fastq.gz"

    BAM="${BAM_DIR}/${RUN}.aligned.sorted.bam"

    FLAGSTAT="${QC_DIR}/${RUN}.flagstat.txt"
    STATS="${QC_DIR}/${RUN}.samtools_stats.txt"
    DEPTH="${QC_DIR}/${RUN}.depth.txt"

    ########################################################
    # Check paired FASTQs
    ########################################################

    if [[ ! -s "$R1" ]]; then
        echo "ERROR: Missing R1:"
        echo "$R1"
        exit 1
    fi

    if [[ ! -s "$R2" ]]; then
        echo "ERROR: Missing R2:"
        echo "$R2"
        exit 1
    fi


    ########################################################
    # Alignment
    ########################################################

    if [[ -s "$BAM" ]]; then

        echo "[SKIP] BAM already exists:"
        echo "$BAM"

    else

        echo "Aligning reads with BWA-MEM..."

        bwa mem \
            -t "$THREADS" \
            -R "@RG\tID:${RUN}\tSM:${SAMPLE}\tPL:ILLUMINA" \
            "$REF" \
            "$R1" \
            "$R2" |
        samtools sort \
            -@ "$THREADS" \
            -o "$BAM" \
            -

    fi


    ########################################################
    # BAM integrity check
    ########################################################

    echo "Checking BAM integrity..."

    samtools quickcheck -v "$BAM"

    echo "[OK] BAM passed samtools quickcheck."


    ########################################################
    # BAM index
    ########################################################

    if [[ ! -s "${BAM}.bai" ]]; then

        echo "Indexing BAM..."

        samtools index \
            -@ "$THREADS" \
            "$BAM"

    else

        echo "[SKIP] BAM index already exists."

    fi


    ########################################################
    # Alignment statistics
    ########################################################

    echo "Generating flagstat..."

    samtools flagstat \
        -@ "$THREADS" \
        "$BAM" \
        > "$FLAGSTAT"


    echo "Generating samtools stats..."

    samtools stats \
        -@ "$THREADS" \
        "$BAM" \
        > "$STATS"


    ########################################################
    # Coverage statistics
    ########################################################

    echo "Calculating genome-wide depth..."

    samtools depth \
        -aa \
        "$BAM" \
        > "$DEPTH"


    ########################################################
    # Extract summary values
    ########################################################

    TOTAL_READS=$(samtools view -c -F 0x900 "$BAM") # 0x900 - combined

    MAPPED_READS=$(samtools view -c -F 0x904 "$BAM")

    PROPER_PAIRS=$(samtools view -c -f 0x2 -F 0x900 "$BAM")


    MAPPING_PERCENT=$(awk \
        -v mapped="$MAPPED_READS" \
        -v total="$TOTAL_READS" \
        'BEGIN {
            if (total > 0)
                printf "%.2f", (mapped/total)*100;
            else
                print "0.00"
        }')


    PROPER_PERCENT=$(awk \
        -v proper="$PROPER_PAIRS" \
        -v total="$TOTAL_READS" \
        'BEGIN {
            if (total > 0)
                printf "%.2f", (proper/total)*100;
            else
                print "0.00"
        }')


    MEAN_DEPTH=$(awk '
        {
            sum += $3
            n++
        }
        END {
            if (n > 0)
                printf "%.2f", sum/n
            else
                print "0.00"
        }
    ' "$DEPTH")


    BREADTH_1X=$(awk '
        {
            total++
            if ($3 >= 1)
                covered++
        }
        END {
            if (total > 0)
                printf "%.2f", (covered/total)*100
            else
                print "0.00"
        }
    ' "$DEPTH")


    BREADTH_10X=$(awk '
        {
            total++
            if ($3 >= 10)
                covered++
        }
        END {
            if (total > 0)
                printf "%.2f", (covered/total)*100
            else
                print "0.00"
        }
    ' "$DEPTH")


    ########################################################
    # Append combined table
    ########################################################

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$GENERATION" \
        "$RUN" \
        "$TOTAL_READS" \
        "$MAPPED_READS" \
        "$MAPPING_PERCENT" \
        "$PROPER_PAIRS" \
        "$PROPER_PERCENT" \
        "$MEAN_DEPTH" \
        "$BREADTH_1X" \
        "$BREADTH_10X" \
        >> "$SUMMARY"


    ########################################################
    # Display important results
    ########################################################

    echo
    echo "Alignment summary for $RUN"
    echo "----------------------------------------------"
    echo "Total reads:             $TOTAL_READS"
    echo "Mapped reads:            $MAPPED_READS"
    echo "Mapping rate:            ${MAPPING_PERCENT}%"
    echo "Properly paired reads:   $PROPER_PAIRS"
    echo "Properly paired rate:    ${PROPER_PERCENT}%"
    echo "Mean genome depth:       ${MEAN_DEPTH}x"
    echo "Genome covered >=1x:     ${BREADTH_1X}%"
    echo "Genome covered >=10x:    ${BREADTH_10X}%"
    echo

done


############################################################
# Final output
############################################################

echo "=============================================="
echo "Alignment completed"
echo "Finished: $(date)"
echo
echo "Summary:"
echo "$SUMMARY"
echo "=============================================="

column -t -s $'\t' "$SUMMARY"
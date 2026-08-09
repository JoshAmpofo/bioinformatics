#!/usr/bin/env bash

set -euo pipefail

# ==========================================================
# SRP144496 RNA-seq
# Stage 3: Gene-level quantification
# featureCounts
# ==========================================================

THREADS="${THREADS:-6}"
STRAND_MODE=2

GTF="reference_genome/gencode_v50/gencode.v50.primary_assembly.annotation.gtf"

ALIGN_DIR="results/03_alignment"
COUNT_DIR="results/06_quantification"
MULTIQC_DIR="results/07_quantification_multiqc"
LOG_DIR="logs"

COUNTS="${COUNT_DIR}/SRP144496_featureCounts.txt"
MATRIX="${COUNT_DIR}/SRP144496_gene_counts.tsv"

mkdir -p \
    "$COUNT_DIR" \
    "$MULTIQC_DIR" \
    "$LOG_DIR"

LOG_FILE="${LOG_DIR}/03_quantification.log"

exec > >(tee -a "$LOG_FILE") 2>&1


die() {
    echo
    echo "ERROR: $1"
    echo "Quantification stopped."
    exit 1
}


echo "===================================================="
echo " SRP144496 RNA-seq Gene Quantification"
echo "===================================================="
echo
echo "Started: $(date)"
echo "Strand mode: $STRAND_MODE (reverse stranded)"
echo


# ==========================================================
# 1. Software checks
# ==========================================================

echo "[1/6] Checking software..."

for PROGRAM in featureCounts samtools awk multiqc
do
    command -v "$PROGRAM" >/dev/null 2>&1 ||
        die "'$PROGRAM' was not found."
done

echo "Software checks passed."
echo


# ==========================================================
# 2. Annotation check
# ==========================================================

echo "[2/6] Checking annotation..."

[[ -s "$GTF" ]] ||
    die "GTF annotation not found: $GTF"

echo "Annotation found."
echo


# ==========================================================
# 3. Collect and validate BAM files
# ==========================================================

echo "[3/6] Checking BAM files..."

BAMS=( "$ALIGN_DIR"/*/*.sorted.bam )

BAM_COUNT=${#BAMS[@]}

echo "Found $BAM_COUNT BAM files."

if [[ "$BAM_COUNT" -ne 16 ]]
then
    die "Expected 16 BAM files but found $BAM_COUNT."
fi

for BAM in "${BAMS[@]}"
do
    echo "Checking $(basename "$BAM")"

    samtools quickcheck "$BAM" ||
        die "Invalid BAM file: $BAM"
done

echo "All BAM files passed validation."
echo


# ==========================================================
# 4. Final featureCounts quantification
# ==========================================================

echo "[4/6] Running featureCounts..."

featureCounts \
    -T "$THREADS" \
    -s "$STRAND_MODE" \
    -t exon \
    -g gene_id \
    -a "$GTF" \
    -o "$COUNTS" \
    "${BAMS[@]}"

[[ -s "$COUNTS" ]] ||
    die "featureCounts output was not generated."

[[ -s "${COUNTS}.summary" ]] ||
    die "featureCounts summary was not generated."

echo
echo "featureCounts completed."
echo


# ==========================================================
# 5. Create clean count matrix
# ==========================================================

echo "[5/6] Creating clean gene-count matrix..."

awk '
BEGIN {
    FS=OFS="\t"
}

NR==1 && /^#/ {
    next
}

$1=="Geneid" {

    printf "gene_id"

    for(i=7; i<=NF; i++) {

        sample=$i

        # Remove directory path
        sub(/^.*\//,"",sample)

        # Remove BAM suffix
        sub(/\.sorted\.bam$/,"",sample)

        printf OFS sample
    }

    printf "\n"

    next
}

{
    printf $1

    for(i=7; i<=NF; i++)
        printf OFS $i

    printf "\n"
}
' "$COUNTS" > "$MATRIX"


[[ -s "$MATRIX" ]] ||
    die "Clean count matrix was not generated."

echo "Count matrix:"
echo "  $MATRIX"
echo


# ==========================================================
# 6. Summarize assignment statistics
# ==========================================================

echo "[6/6] Read-assignment summary..."
echo

SUMMARY="${COUNTS}.summary"

awk '
BEGIN {
    FS=OFS="\t"
}

NR==1 {

    for(i=2;i<=NF;i++) {

        name[i]=$i

        sub(/^.*\//,"",name[i])
        sub(/\.sorted\.bam$/,"",name[i])
    }

    next
}

{
    category[NR]=$1

    for(i=2;i<=NF;i++) {

        count[NR,i]=$i
        total[i]+=$i

        if($1=="Assigned")
            assigned[i]=$i
    }
}

END {

    printf "%-15s %15s %15s %12s\n",
           "SAMPLE",
           "TOTAL",
           "ASSIGNED",
           "ASSIGNED_%"

    for(i=2;i<=NF;i++) {

        pct=100*assigned[i]/total[i]

        printf "%-15s %15d %15d %11.2f%%\n",
               name[i],
               total[i],
               assigned[i],
               pct
    }
}
' "$SUMMARY"


# Save assignment percentages to a TSV

awk '
BEGIN {
    FS=OFS="\t"
}

NR==1 {

    for(i=2;i<=NF;i++) {

        name[i]=$i
        sub(/^.*\//,"",name[i])
        sub(/\.sorted\.bam$/,"",name[i])
    }

    next
}

{
    for(i=2;i<=NF;i++) {

        total[i]+=$i

        if($1=="Assigned")
            assigned[i]=$i
    }
}

END {

    print "sample","total_reads","assigned_reads","assigned_percent"

    for(i=2;i<=NF;i++)

        print name[i],
              total[i],
              assigned[i],
              100*assigned[i]/total[i]
}
' "$SUMMARY" \
> "${COUNT_DIR}/assignment_rates.tsv"


echo
echo "Generating MultiQC report..."

multiqc \
    "$COUNT_DIR" \
    --outdir "$MULTIQC_DIR" \
    --filename SRP144496_quantification_multiqc.html \
    --force


echo
echo "===================================================="
echo " QUANTIFICATION COMPLETE"
echo "===================================================="
echo
echo "Full featureCounts output:"
echo "  $COUNTS"
echo
echo "Clean DESeq2 count matrix:"
echo "  $MATRIX"
echo
echo "Assignment statistics:"
echo "  ${COUNT_DIR}/assignment_rates.tsv"
echo
echo "MultiQC:"
echo "  ${MULTIQC_DIR}/SRP144496_quantification_multiqc.html"
echo
echo "Finished: $(date)"
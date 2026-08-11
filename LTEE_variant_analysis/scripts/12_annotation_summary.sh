#!/usr/bin/env bash

set -euo pipefail

INPUT="results/statistics/annotation/all_annotated_variants.tsv"

OUT_DIR="results/statistics/annotation"

############################################################
# Impact summary
############################################################

awk -F '\t' '
NR > 1 {
    key=$2 "\t" $11
    count[key]++
}
END {
    print "generation\timpact\tcount"

    for (key in count)
        print key "\t" count[key]
}
' "$INPUT" |
sort -t $'\t' -k1,1n -k2,2 \
> "${OUT_DIR}/impact_summary.tsv"


############################################################
# Consequence summary
############################################################

awk -F '\t' '
NR > 1 {
    key=$2 "\t" $10
    count[key]++
}
END {
    print "generation\tconsequence\tcount"

    for (key in count)
        print key "\t" count[key]
}
' "$INPUT" |
sort -t $'\t' -k1,1n -k3,3nr \
> "${OUT_DIR}/consequence_summary.tsv"


############################################################
# Gene summary
############################################################

awk -F '\t' '
NR > 1 && $12 != "" {
    key=$2 "\t" $12
    count[key]++
}
END {
    print "generation\tgene\tannotations"

    for (key in count)
        print key "\t" count[key]
}
' "$INPUT" |
sort -t $'\t' -k1,1n -k3,3nr \
> "${OUT_DIR}/gene_summary.tsv"


############################################################
# High-impact variants
############################################################

awk -F '\t' '
BEGIN {OFS="\t"}
NR==1 || $11=="HIGH"
' "$INPUT" \
> "${OUT_DIR}/high_impact_variants.tsv"


echo "Annotation summaries created."
echo

echo "=== IMPACT ==="
column -t -s $'\t' \
    "${OUT_DIR}/impact_summary.tsv"

echo
echo "=== HIGH IMPACT ==="
column -t -s $'\t' \
    "${OUT_DIR}/high_impact_variants.tsv" |
head -30
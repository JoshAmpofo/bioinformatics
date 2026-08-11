#!/usr/bin/env bash

set -euo pipefail

INPUT="results/statistics/annotation/all_annotated_variants.tsv"

OUT_DIR="results/statistics/annotation"

OUTPUT="${OUT_DIR}/primary_variant_annotations.tsv"

############################################################
# Select the highest-impact annotation for each unique
# sample + genomic variant.
#
# Priority:
#
# HIGH > MODERATE > LOW > MODIFIER
############################################################

awk -F '\t' '
BEGIN {
    OFS="\t"

    severity["MODIFIER"]=1
    severity["LOW"]=2
    severity["MODERATE"]=3
    severity["HIGH"]=4
}

NR==1 {
    header=$0
    next
}

{
    key=$1 "|" $4 "|" $5 "|" $6 "|" $7

    score=severity[$11]

    if (!(key in best_score) || score > best_score[key]) {

        best_score[key]=score
        best[key]=$0
    }
}

END {

    print header

    for (key in best)
        print best[key]
}
' "$INPUT" \
| {
    read -r header

    printf "%s\n" "$header"

    sort \
        -t $'\t' \
        -k2,2n \
        -k5,5n
} \
> "$OUTPUT"


echo "Primary annotation table created:"
echo "$OUTPUT"

echo

column -t -s $'\t' "$OUTPUT" |
head -30
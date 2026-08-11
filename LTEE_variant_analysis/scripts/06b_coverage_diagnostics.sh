#!/usr/bin/env bash

set -euo pipefail

DEPTH_DIR="results/statistics/alignment"
OUT_DIR="results/statistics/coverage_gaps"

mkdir -p "$OUT_DIR"

for DEPTH in "$DEPTH_DIR"/*.depth.txt
do

    RUN=$(basename "$DEPTH" .depth.txt)

    echo "========================================"
    echo "Examining $RUN"
    echo "========================================"

    OUT="${OUT_DIR}/${RUN}.zero_coverage.bed"

    # Convert consecutive zero-depth positions into BED intervals
    awk '
    $3 == 0 {
        if (!open) {
            chr=$1
            start=$2
            open=1
        }

        end=$2
        next
    }

    open {
        print chr "\t" start-1 "\t" end
        open=0
    }

    END {
        if (open)
            print chr "\t" start-1 "\t" end
    }
    ' "$DEPTH" > "$OUT"

    echo
    echo "Number of zero-coverage intervals:"

    wc -l < "$OUT"

    echo
    echo "Total bases with zero coverage:"

    awk '
    {
        sum += ($3-$2)
    }
    END {
        print sum
    }
    ' "$OUT"

    echo
    echo "Ten largest zero-coverage intervals:"

    awk '
    BEGIN {
        OFS="\t"
    }
    {
        print $1,$2,$3,$3-$2
    }
    ' "$OUT" |
        sort -k4,4nr |
        head -n 10

    echo

done
#!/usr/bin/env bash

set -euo pipefail

DIR="results/05_strandedness"

printf "\n%-15s %10s %10s %10s\n" \
    "SAMPLE" "s0 (%)" "s1 (%)" "s2 (%)"

printf "%-15s %10s %10s %10s\n" \
    "---------------" "----------" "----------" "----------"

for summary in "$DIR"/counts_s0.txt.summary
do

    awk -F'\t' '
    NR==1 {
        for(i=2;i<=NF;i++) {
            sample[i]=$i
            sub(/^.*\//,"",sample[i])
            sub(/\.sorted\.bam$/,"",sample[i])
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
        for(i=2;i<=NF;i++)
            printf "%s\t%.4f\n",
                sample[i],
                100*assigned[i]/total[i]
    }' "$DIR/counts_s0.txt.summary" \
      > /tmp/s0.tsv
done

awk -F'\t' '
NR==1 {
    for(i=2;i<=NF;i++) {
        sample[i]=$i
        sub(/^.*\//,"",sample[i])
        sub(/\.sorted\.bam$/,"",sample[i])
    }
    next
}
{
    for(i=2;i<=NF;i++) {
        total[i]+=$i
        if($1=="Assigned") assigned[i]=$i
    }
}
END {
    for(i=2;i<=NF;i++)
        printf "%s\t%.4f\n",
            sample[i],
            100*assigned[i]/total[i]
}' "$DIR/counts_s1.txt.summary" > /tmp/s1.tsv

awk -F'\t' '
NR==1 {
    for(i=2;i<=NF;i++) {
        sample[i]=$i
        sub(/^.*\//,"",sample[i])
        sub(/\.sorted\.bam$/,"",sample[i])
    }
    next
}
{
    for(i=2;i<=NF;i++) {
        total[i]+=$i
        if($1=="Assigned") assigned[i]=$i
    }
}
END {
    for(i=2;i<=NF;i++)
        printf "%s\t%.4f\n",
            sample[i],
            100*assigned[i]/total[i]
}' "$DIR/counts_s2.txt.summary" > /tmp/s2.tsv

paste /tmp/s0.tsv /tmp/s1.tsv /tmp/s2.tsv |
awk 'BEGIN {
    printf "%-15s %10s %10s %10s\n",
           "SAMPLE","s0 (%)","s1 (%)","s2 (%)"
}
{
    printf "%-15s %10.2f %10.2f %10.2f\n",
           $1,$2,$4,$6
}'
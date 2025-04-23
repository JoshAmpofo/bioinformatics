#!/usr/bin/env python3


"""
Write a program that will calculate the number of all kmers of a given length
across all DNA sequences in the input files and display just the ones that occur more than the given number of times.
Your program should take the following command line arguments:
1. The length of the kmers to be counted
2. The minimum number of times a kmer must occur to be displayed
3. The input files to be processed
"""

import sys
import os

# convert command line arguments to variables
kmer_size = int(sys.argv[1])
min_count = int(sys.argv[2])

# define function to split dna
def split_dna(dna, kmer_size):
    kmers = []
    for start in range(0, len(dna)-(kmer_size - 1), 1):
        kmer = dna[start:start + kmer_size]
        kmers.append(kmer)
    return kmers

# create an empty dictionary to hold the counts
kmer_counts = {}

# process each file with the right name
data_dir = '../../exercises and examples/working_with_the_filesystem/exercises/'
for filename in os.listdir(data_dir):
    if filename.endswith('.dna'):
        file_path = os.path.join(data_dir, filename)
        with open(file_path, 'r') as dna_file:
            for line in dna_file:
                dna = line.strip()
                
                # increase the count for each kmer found
                for kmer in split_dna(dna, kmer_size):
                    current_count = kmer_counts.get(kmer, 0)
                    new_count = current_count + 1
                    kmer_counts[kmer] = new_count

# print the kmers that occur more than the minimum number of times
for kmer, count in kmer_counts.items():
    if count > min_count:
        print(f"{kmer}: {count}")
        
        

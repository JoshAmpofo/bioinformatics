#!/usr/bin/env python3

# Read file containing genomic data and split into coding and non-coding DNA, saving both sequences in separate files

# access file and read content
genomic_dna_file = open("../exercises and examples/reading_files/exercises/genomic_dna.txt")

# read contents
dna_content = genomic_dna_file.read().strip()

# split into coding and non-coding regions
exon_1 = dna_content[:64]
exon_2 = dna_content[91:]
intron = dna_content[63:91]

coding_regions = exon_1 + exon_2
non_coding_regions = intron

# write coding and non_coding to different files
coding_region_file = open("coding_regions.txt", "w")
non_coding_region_file = open("non_coding_regions.txt", "w")

my_coding_dna = coding_region_file.write(coding_regions)
my_non_coding_dna = non_coding_region_file.write(non_coding_regions)

# close files
genomic_dna_file.close()
coding_region_file.close()
non_coding_region_file.close()
# print content to be sure file is read correctly
# print(dna_content)

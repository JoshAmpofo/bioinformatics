#!/usr/bin/env python3

'''
Description: Write a program that will extract exon segments from a file, concatenate them and write them to a new file. 
The program has to:
    1. read the exon file line by line
    2. split each exon line into two numbers
    3. turn those numbers into integers
    4. extract the matching part of the genomic DNA sequence
    5. concatenate all the exon sequences together
'''

# open appropriate files
dna = open("../../exercises and examples/lists_and_loops/exercises/genomic_dna.txt").read()
exons = open("../../exercises and examples/lists_and_loops/exercises/exons.txt")

# store coding sequences (from sliced exon positions)
coding_sequence = ""

# load contents
for line in exons:
    positions = line.strip().split(',') # split exon positions

    # get beginning and ending slice positions (convert to int)
    start = int(positions[0])
    end = int(positions[1])
    
    exon = dna[start:end] # get exon sequences
    #print(f"Positions: {start}:{end} exon: {exon}") # visualize what is been added to output file
    coding_sequence += exon # append exons to coding sequence

# create and write new exons to file
new_exon_file = open("new_exons.txt", "w")
new_exon_file.write(coding_sequence)

# close files
exons.close()
new_exon_file.close()
        
    

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
dna = open("../../exercises and examples/lists_and_loops/exercises/genomic_dna.txt")
exons = open("../../exercises and examples/lists_and_loops/exercises/exons.txt")

positions = [] # set list to hold split exon positions

# load contents
for line in exons.readlines():
    line = line.strip().split(',') # split exon positions
    positions.append(line)

# store sliced exons from sequence
concatenated_exons = ""

# read dna sequence
sequence = dna.read().strip()

# get beginning and ending slice positions
for lst in positions:
    start = int(lst[0])
    end = int(lst[1])
    
    exon = sequence[start:end] # get exons from positions
    #print(f"Positions: {start}:{end} exon: {exon}") # visualize what is been added to output file
    concatenated_exons += exon # combine new exons into one string

# create and write new wxons to file
new_exon_file = open("new_exons.txt", "w")
new_exon_file.write(concatenated_exons)

# close files
dna.close()
exons.close()
        
    

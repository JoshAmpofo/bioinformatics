#!/usr/bin/env python3

"""
Description: input.txt contains a number of DNA sequences, one per line.
Each sequence starts with the same 14 base pair fragment - a sequencing adapter that should be removed.

Task: Write a program that will:
    a. trim this adapter and write cleaned sequences to a new file
    b. print the length of each sequence to the screen
"""

# get sequence file
dna_sequences = open("../../exercises and examples/lists_and_loops/exercises/input.txt")
trimmed_sequences = []

# write a loop to access the DNA sequences
for dna_line in dna_sequences.readlines():
    trimmed_sequence = dna_line[14:] # trim the adapter sequence
    trimmed_sequences.append(trimmed_sequence)
    dna_sequences.close()

for sequence in trimmed_sequences:
    new_sequence_file = open("trimmed_sequences.txt", "a") # create a new file to hold the new sequences
    new_sequence_file.write(sequence) # write trimmed/cleaned sequences to new file
    
    # close files
    new_sequence_file.close()
    
    # print length
    print(f"Length of trimmed sequences: {len(sequence)}")

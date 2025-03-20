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

# create a new file to hold the new sequences
new_sequence_file = open("trimmed_sequences.txt", "w")

# write a loop to access the DNA sequences
for dna_line in dna_sequences:
    trimmed_sequence = dna_line[14:] # trim the adapter sequence
    new_sequence_file.write(trimmed_sequence) # write trimmed/cleaned sequences to new file
    # print length
    print(f"Length of trimmed sequences: {len(trimmed_sequence)}")

# close file
dna_sequences.close()

    


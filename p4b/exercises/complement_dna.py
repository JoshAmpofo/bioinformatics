#!/usr/bin/env python3

# Generate the complement of a DNA Sequence

# sequence
sequence = "ACTGATCGATTACGTATAGTATTTGCTATCATACATATATATCGATGCGTTCAT"

# replace A with T, T with A, C with G and G with C
DNAcomplement = "" # create an empty string to store complement bases

for base in sequence:
    if base == "A":
        DNAcomplement += "T"
    elif base == "T":
        DNAcomplement += "A"
    elif base == "C":
        DNAcomplement += "G"
    elif base == "G":
        DNAcomplement += "C"

# return complement
print(f"Original sequence: {sequence}\nComplement: {DNAcomplement}")

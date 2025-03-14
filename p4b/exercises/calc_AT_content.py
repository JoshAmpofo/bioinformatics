#!/usr/bin/env python

# Calculate the AT content of a given sequence

# sequence
sequence = "ACTGATCGATTACGTATAGTATTTGCTATCATACATATATATCGATGCGTTCAT"

# run calculations
at_content = sequence.count('A') + sequence.count('T') / len(sequence) * 100

# return value
print(f"The AT content of the sequence {sequence} is {round(at_content, 2)}%")

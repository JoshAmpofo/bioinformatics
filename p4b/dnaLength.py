#!/usr/bin/env python3

# A simple program for calculating the length of DNA sequence

# get DNA sequence
sequence = input("Provide DNA sequence: ")

# calcculate length of DNA
length = len(sequence)

# return a nice statement to user about the length of their sequence
print(f"The length of your sequence {sequence} is {length}")

#!/usr/bin/env python3

"""
A simple script that takes a DNA sequence (as a string) and returns the following:
    - length of sequence
    - number of A C T G present in sequence
    - GC content
"""


print("======= Simple Sequence Analyzer =======")
print("Prints length, nucleotide content and GC content on input sequence\n")


# take sequence input
seq_input = input("Enter a sequence: ")
print()


# convert sequence to upper
seq_input = seq_input.upper()


# length of sequence
seq_length = len(seq_input)


# ATCG content
a_count = seq_input.count("A")
c_count = seq_input.count("C")
g_count = seq_input.count("G")
t_count = seq_input.count("T")


# GC content
gc_total = g_count + c_count
gc_content = gc_total / seq_length


print("Analyzing your Sequence...\n")
# Print all results
print("Length of your sequence is", seq_length, "\n")
print("These are the number of A C T Gs in your sequence:\n")
print(f"A: {a_count} | C: {c_count} | T: {t_count} | G: {g_count}\n")
print(f"GC content of your sequence: {gc_content:.4f}\n")

print("Thank you for using this simple sequence analayzer. Have a great day!")

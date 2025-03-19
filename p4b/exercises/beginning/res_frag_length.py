#!/usr/bin/env python3

# calculate the length of restriction fragments

# target sequence
sequence = "ACTGATCGATTACGTATAGTAGAATTCTATCATACATATATATCGATGCGTTCAT"
substring = "GAATTC"

restriction_site_pos = sequence.find(substring)

# print restriction site position
print(f"Location of restriction site: {restriction_site_pos}")

# get lengths
first_frag_length = len(sequence[:restriction_site_pos+1])
second_frag_length = len(sequence[restriction_site_pos+1:])

# print lengths
print(f"Lengths of fragments after restriction digests:\nFragment 1: {first_frag_length}\nFragment 2: {second_frag_length}")


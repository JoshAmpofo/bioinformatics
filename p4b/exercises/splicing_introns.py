#!/usr/bin/env python3


##### PART ONE ####
# find the introns in a given DNA sequence and return only the coding regions

# sequence
sequence = "ATCGATCGATCGATCGACTGACTAGTCATAGCTATGCATGTAGCTACTCGATCGATCGATCGATCGATCGATCGATCGATCGATCATGCTATCATCGATCGATATCGATGCATCGACTACTAT"
exon1_loc = 63
exon2_loc = 91

# first and second exon sequences
exon_1 = sequence[:exon1_loc+1]
exon_2 = sequence[exon2_loc:]
intron_sequence = sequence[exon1_loc+1:exon2_loc]
# get full coding regions
full_coding_regions = exon_1 + exon_2

# print results
print(f"Original Sequence: {sequence}\nIntron Sequence: {intron_sequence}\nFull coding regions: {full_coding_regions}")
print(f"Lengths:\nOriginal sequence length: {len(sequence)}\nIntron Length: {len(intron_sequence)}\nFull coding region length: {len(full_coding_regions)}")


##### PART TWO #######

# calculate the percentage of the sequence that is coding
cod_region_length = len(full_coding_regions) # get total length of coding region sequence
orig_seq_length = len(sequence) # get total length of original sequence

percent_coding_region = (cod_region_length / orig_seq_length) * 100 # get coding region percentage

# print results
print("##############################################################")
print(f"Percentage of DNA sequence that is coding: {round(percent_coding_region, 4)}")


########### PART THREE #################################

# print out the full sequence with coding region in uppercase and non-coding in lowercase
non_coding = intron_sequence.lower()
full_sequence = exon_1.upper() + non_coding + exon_2.upper()
# print
print("##################################################################")
print(f"Full Sequence: {full_sequence}")

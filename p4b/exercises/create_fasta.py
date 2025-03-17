#!/usr/bin/env python3

# Create a fasta file containing some sequence information

# content to put into fasta file
content_1 = ">ABC123\nATCGTACGATCGATCGATCGCTAGACGTATCG\n"
content_2 = ">DEF456\nactgatcgacgatcgatcgatcacgact\n".upper()
content_3 = ">HIJ789\nACTGACACTGT--ACTGTA----CATGTG".replace("-","")

# open file
fasta_sequences = open("fasta_sequences.fasta", "w")
fasta_sequences_2 = open("fasta_sequences.fasta", "a") # add next sequence to file instead of overwriting
fasta_sequences_3 = open("fasta_sequences.fasta", "a")

# write content to file
file_content = fasta_sequences.write(content_1)
file_content = fasta_sequences_2.write(content_2)
file_content = fasta_sequences_3.write(content_3)

# close file to flush system
fasta_sequences.close()

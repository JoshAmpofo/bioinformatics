#!/usr/bin/env python3

# Create multiple fasta files

# get content for each fasta file
content_1 = ">ABC123\nATCGTACGATCGATCGATCGCTAGACGTATCG"
content_2 = ">DEF456\nactgatcgacgatcgatcgatcacgact".upper()
content_3 = ">HIJ789\nACTGAC-ACTGT--ACTGTA----CATGTG".replace("-", "")

# create fasta files
fasta_1 = open("ABC123.fasta", "w")
fasta_2 = open("DEF456.fasta", "w")
fasta_3 = open("HIJ789.fasta", "w")

# write the content to each file
fasta_1.write(content_1)
fasta_2.write(content_2)
fasta_3.write(content_3)

# close files
fasta_1.close()
fasta_2.close()
fasta_3.close()

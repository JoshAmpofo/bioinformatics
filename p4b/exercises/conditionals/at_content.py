#!/usr/bin/env python

"""
Read data from a csv file and print out gene names for all genes
whose AT content is less than 0.5 and whose expression level is greater than 200.
"""


def get_at_content(data):
    """
    Read data from a csv file and print out gene names for all genes
    whose AT content is less than 0.5 and whose expression level is greater than 200.

    """
    results = []
    with open(data, "r") as file:
        lines = file.readlines()

    for line in lines:
        split_lines = line.split(",")  # split lines
        # get sequence
        gene_sequence = split_lines[1].upper()
        # get AT content
        a_count = gene_sequence.count("A")
        t_count = gene_sequence.count("T")
        seq_length = len(gene_sequence)
        at_content = (a_count + t_count) / seq_length
        round_at_content = float(round(at_content, 2))
        # get expression levels
        expression_level = int(split_lines[3])

    # select genes with AT content < 0.5 and expression level > 200
    if round_at_content < 0.5 and expression_level > 200:
        organism_name = split_lines[0]
        gene_name = split_lines[2]
        results.append((gene_name, round_at_content))
    
    return results


def main():
    data = input("Enter data file location: ")
    gene_data = get_at_content(data)
    for gene_name, at_content in gene_data:
        print(f"Gene Name: {gene_name}, AT content: {at_content}")


if __name__ == "__main__":
    main()

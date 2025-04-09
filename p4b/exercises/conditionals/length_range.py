#!/usr/bin/env python3

"""
Read a csv file and print out the gene names for all genes between 90 and 110 bases long
"""


def length_range(data):
    """
    Return a list of gene names for genes between 90 and 110 bases long

    Agr(s):
        data (csv): csv file, each containing a gene's name and length

    Returns:
        str: gene names
    """
    results = []
    with open(data, "r") as file:
        lines = file.readlines()

    for line in lines:
        split_lines = line.split(",")  # split lines
        gene_name = split_lines[2].strip()  # retrieve gene name
        gene_length = int(len(split_lines[1].strip()))  # retrieve gene length
        # check for appropriate gene length
        if 90 <= gene_length <= 110:
            results.append((gene_name, gene_length))
    return results


def main():
    data = input("Enter data file location: ")
    gene_data = length_range(data)
    for gene_name, gene_length in gene_data:
        print(f"Gene Name: {gene_name}, Gene Length: {gene_length}")


if __name__ == "__main__":
    main()

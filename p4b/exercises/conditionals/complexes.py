#!/usr/bin/env python3

"""
Print out the gene names for all genes whose name begins with "k" or "h" except
those belonging to Drosophila melanogater
"""


def gene_names_with_h_or_k(data):
    """
    Print out the gene names for all genes whose name begins with "k" or "h" except
    those belonging to Drosophila melanogater

    Arg(s):
        data (file object): A file object opened in read mode

    Returns:
        Gene names
    """
    # create an empty list to hold organism and gene names
    results = []

    # read the contents of the provided data file
    data_content = open(data, "r")
    for line in data_content:
        line = line.strip()

        # check if starting line name is not Drosophila melanogaster and split into components
        if line.startswith("Drosophila melanogaster") == False:
            split_line = line.split(",")
            organism_name = split_line[0]
            gene_name = split_line[2]
            
            if gene_name.startswith("h") or gene_name.startswith("k"):
                results.append((organism_name, gene_name))  # add organism name and gene name to results
    data_content.close()  # close the file after reading

    return results


def main():
    # call the function and print the results
    data = input("Enter data file location: ")
    results = gene_names_with_h_or_k(data)
    for organism_name, gene_name in results:
        print(f"{organism_name}: {gene_name}")


if __name__ == "__main__":
    main()

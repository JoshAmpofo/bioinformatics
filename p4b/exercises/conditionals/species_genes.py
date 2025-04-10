#!/usr/bin/env python3

"""
Read the data.csv file and print the names for all genes belonging to
Drosophila melanogaster or Drosophila simulans
"""


def gene_names(data):
    """
    Read a data file and print the names for all genes belonging to
    Drosophila melanogaster or Drosophila simulans

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

        # check for the appropriate starting organism names and split into components
        if line.startswith("Drosophila melanogaster") or line.startswith(
            "Drosophila simulans"
        ):
            split_line = line.split(",")
            organism_name = split_line[0]
            gene_name = split_line[2]

            results.append(
                (organism_name, gene_name)
            )  # add organism name and gene name to results
    data_content.close()  # close the file after reading

    return results


def main():
    data = input("Enter data file location: ")
    gene_data = gene_names(data)
    for organism_name, gene_name in gene_data:
        print(f"{organism_name}: {gene_name}")


if __name__ == "__main__":
    main()

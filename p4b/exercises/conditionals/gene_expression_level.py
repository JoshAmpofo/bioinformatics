#!/usr/bin/env python3

"""
For each gene in the input file, print out a message giving the gene name and saying whether its AT content is high
(greater than 0.65), low (less than 0.45), or medium (between 0.45 and 0.65).
"""


def get_at_content(data):
    """
    Calculate the AT content of a gene.
    """
    results = []
    with open(data, "r") as file:
        lines = file.readlines()

    for line in lines:
        split_line = line.strip().split(",")
        organism_name = split_line[0]
        gene_sequence = split_line[1].upper()
        gene_name = split_line[2]

        # Calculate AT content
        at_content = (gene_sequence.count("A") + gene_sequence.count("T")) / len(
            gene_sequence
        )

        results.append((organism_name, gene_name, at_content))

    return results


def classify_at_content(at_content):
    """
    Classify the AT content of a gene.
    """
    if at_content > 0.65:
        return "high"
    elif at_content < 0.45:
        return "low"
    else:
        return "medium"


def main():
    data = input("Please enter filename or location: ")
    results = get_at_content(data)
    for organism_name, gene_name, at_content in results:
        classification = classify_at_content(at_content)
        print(
            f"{organism_name} {gene_name} AT content is {classification} at {at_content:.2f}"
        )


if __name__ == "__main__":
    main()

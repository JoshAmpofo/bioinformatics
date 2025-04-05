#!/usr/bin/env python3

"""
Write a function that takes two arguments - a protein sequence and an amino acid residue
- and returns the percentage of the protein that the amino acid makes up.
Use the following assertions to test your function:
    assert my_function("MSRSLLLRFLLFLLLLPPLP", "M") == 5
    assert my_function("MSRSLLLRFLLFLLLLPPLP", "r") == 10
    assert my_function("msrslllrfllfllllpplp", "L") == 50
    assert my_function("MSRSLLLRFLLFLLLLPPLP", "Y") == 0
"""


def get_residue_percent(protein, residue, sig_figs=2):
    """
    Calculate the percentage of an amino acid residue in a sequence.

    Arg(s):
        protein (str): input protein sequence to calculate residue percentage
        residue (str): amino acid residue
        sig_figs (int): significant figures to report percentage value
    """

    # convert protein sequence and residue to uppercase
    protein = protein.upper()
    residue = residue.upper()
    # get length of protein
    prot_length = len(protein)
    # get residue count in protein
    residue_count = protein.count(residue)

    # get residue percentage
    res_percent = (residue_count / prot_length) * 100

    return float(round(res_percent, sig_figs))


if __name__ == "__main__":
    result = get_residue_percent(protein="MSRSLLL", residue="M", sig_figs=3)
    print(f"Residue percent: {result}")

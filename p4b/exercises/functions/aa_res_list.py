#!/usr/bin/env python3

"""
Modify the function from part one so that it accepts a list of amino acid residues
rather than a single one. If no list is given, the function should return the
percentage of hydrophobic amino acid residues (A, I, L, M, F, W, Y and V). Your
function should pass the following assertions:
    assert my_function("MSRSLLLRFLLFLLLLPPLP", ["M"]) == 5
    assert my_function("MSRSLLLRFLLFLLLLPPLP", ['M', 'L']) == 55
    assert my_function("MSRSLLLRFLLFLLLLPPLP", ['F', 'S', 'L']) == 70
    assert my_function("MSRSLLLRFLLFLLLLPPLP") == 65
"""


def get_multi_aa_res(protein, residue=[], sig_figs=2):
    """
    Calculate the percentage of an amino acid residue in a sequence.

    Arg(s):
        protein (str): input protein sequence to calculate residue percentage
        residue (list): list of amino acid residues
        sig_figs (int): significant figures to report percentage value
    """
    # convert protein sequence and residue to uppercase
    protein = protein.upper()
    prot_length = len(protein)
    res_count = 0 # set counter to count all residues present in protein
    
    if not residue:
        residue = ["A", "I", "L", "M", "F", "W", "Y", "V"]
        for res in residue:
            res_count += protein.count(res)
    elif residue:
        for res in residue:
            res = res.upper()
            res_count += protein.count(res)
    
    # calculate residue percentage
    res_percent = (res_count / prot_length) * 100
    
    return round(res_percent, sig_figs)


if __name__ == "__main__":
    print(get_multi_aa_res("MSRSLLLRFLLFLLLLPPLP", ["M", "L"]))
    
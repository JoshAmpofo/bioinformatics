#!/usr/bin/env python3


"""
Predict the fragment lengths that will be produced when a sequence is 
digested by two restriction enzymes.
 - AbcI whose recognition site is ANT/AAT
 - AbcII whose recognition site is GCRW/TG
"""


import re


def digest(dna: str) -> str:
    """
    Simulate the digestion of a DNA sequence by two restriction enzymes using regex.
    
    Args:
        dna (str): The DNA sequence to be digested.
    
    Returns:
        str: The resulting fragments after digestion.
    """
    # find cut sites of individual enzymes
    # create a starting position of cuts
    all_cuts = [0]
    
    # find cut positions for AbcI
    for match in re.finditer(r"A[ATGC]TAAT", dna):
        all_cuts.append(match.start() + 3)
    
    # find cut positions for AbcII
    for match in re.finditer(r"GC[AG][AT]TG", dna):
        all_cuts.append(match.start() + 4)
    
    # add the final positions
    all_cuts.append(len(dna))
    # sort the cut positions
    sorted_cuts = sorted(all_cuts)
    
    frag_lengths = []
    for i in range(1, len(sorted_cuts)):
        current_cut_pos = sorted_cuts[i]
        prev_cut_pos = sorted_cuts[i - 1]
        # calculate the fragment length
        fragment_length = current_cut_pos - prev_cut_pos
        frag_lengths.append(fragment_length)
    return frag_lengths

   
def main():
    data = input("Enter sequence file location: ")
    with open(data, 'r') as file:
        dna = file.read().strip()
        fragments = digest(dna)
        print(f"Fragments after digestion: {fragments}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

"""
Use the gencode dict to write a program which will translate a DNA sequence
into protein.
TO-DO:
    - split the DNA sequence into codons
    - look up the amino acide resisude for each codon
    - join all tha mino acids to give a protein
Test the program on a couple of different inputs to see what happens.
How does your program cope with a sequence whose length is not a multiple of 3?
How does it cope with a sequence that contains unknown bases?
"""

def create_codon_list(dna_sequence) -> list:
    """
    Split a given dna sequence into its codon collection.
    
    Arg(s):
        dna_sequence (str): input dna sequence
    
    Return(s):
        list: list of codons.
        NB: the input sequence is trimmed for sequences whose length exceed the multiples of three rule 
    """
    # for now let's trim sequences that are not multiples of three
    trimmed_sequence = dna_sequence[:len(dna_sequence) - len(dna_sequence) % 3]
    
    codons = []
    for nucleotide in range(0, len(trimmed_sequence), 3):
        codon = dna_sequence[nucleotide:nucleotide+3]
        codons.append(codon)
        
    return codons

        
def translate_dna(codons: list) -> str:
    """
    Takes a list of codons and translates them to proteins.
    
    Arg(s):
        codons (list): list of codons
    
    Returns:
        str: protein sequence string 
    """
    gencode = { 'ATA':'I', 'ATC':'I', 'ATT':'I', 'ATG':'M',
               'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACT':'T',
               'AAC':'N', 'AAT':'N', 'AAA':'K', 'AAG':'K',
               'AGC':'S', 'AGT':'S', 'AGA':'R', 'AGG':'R', 
               'CTA':'L', 'CTC':'L', 'CTG':'L', 'CTT':'L', 
               'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCT':'P', 
               'CAC':'H', 'CAT':'H', 'CAA':'Q', 'CAG':'Q', 
               'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGT':'R', 
               'GTA':'V', 'GTC':'V', 'GTG':'V', 'GTT':'V', 
               'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCT':'A', 
               'GAC':'D', 'GAT':'D', 'GAA':'E', 'GAG':'E', 
               'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGT':'G', 
               'TCA':'S', 'TCC':'S', 'TCG':'S', 'TCT':'S', 
               'TTC':'F', 'TTT':'F', 'TTA':'L', 'TTG':'L', 
               'TAC':'Y', 'TAT':'Y', 'TAA':'_', 'TAG':'_', 
               'TGC':'C', 'TGT':'C', 'TGA':'_', 'TGG':'W'
            }
    # loop through codon list and check for their corresponding amino acid residue
    protein = []
    for codon in codons:
        prot_residue = gencode.get(codon)
        protein.append(prot_residue)
    
    prot_sequence = "".join(protein)
    # print(prot_sequence)
    return prot_sequence


def main():
    dna_seq = input("Please enter a nucleotide sequence: ")
    codons = create_codon_list(dna_seq)
    print(codons)
    protein_sequence = translate_dna(codons)
    
    print(f"Protein sequence is: {protein_sequence}")
    

if __name__ == "__main__":
    main()
        
        
    
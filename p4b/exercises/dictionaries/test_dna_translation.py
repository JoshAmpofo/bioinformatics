#!/usr/bin/env python3

from dna_translation import create_codon_list, translate_dna

def test_create_codon_list():
    # Test with a sequence that's a multiple of 3
    assert create_codon_list("ATGCGT") == ["ATG", "CGT"], "Failed to split sequence that's multiple of 3"
    
    # Test with a sequence that's not a multiple of 3 (should trim)
    assert create_codon_list("ATGCGTA") == ["ATG", "CGT"], "Failed to trim sequence that's not multiple of 3"
    
    # Test with empty sequence
    assert create_codon_list("") == [], "Failed to handle empty sequence"
    
    # Test with sequence less than 3 bases
    assert create_codon_list("AT") == [], "Failed to handle sequence less than 3 bases"

def test_translate_dna():
    # Test basic translation
    assert translate_dna(["ATG", "CGT"]) == "MR", "Failed basic translation"
    
    # Test with stop codon
    assert translate_dna(["ATG", "TAA"]) == "M_", "Failed to handle stop codon"
    
    # Test with tryptophan (W)
    assert translate_dna(["TGG"]) == "W", "Failed to translate tryptophan"
    
    # Test with multiple amino acids
    assert translate_dna(["ATG", "GCA", "TGG"]) == "MAW", "Failed to translate multiple amino acids"
    
    # Test with empty codon list
    assert translate_dna([]) == "", "Failed to handle empty codon list"

if __name__ == '__main__':
    test_create_codon_list()
    test_translate_dna()
    print("All tests passed!") 
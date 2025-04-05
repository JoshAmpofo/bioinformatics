#!/usr/bin/env python3
from aa_residue_percentage import get_residue_percent

# Test Cases for Amino Acid Residue Percentage
assert get_residue_percent("MSRSLLLRFLLFLLLLPPLP", "M") == 5
assert get_residue_percent("MSRSLLLRFLLFLLLLPPLP", "r") == 10
assert get_residue_percent("msrslllrfllfllllpplp", "L") == 50
assert get_residue_percent("MSRSLLLRFLLFLLLLPPLP", "Y") == 0

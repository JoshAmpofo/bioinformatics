#!/usr/bin/env python3

from aa_res_list import get_multi_aa_res

# Test Cases
assert get_multi_aa_res("MSRSLLLRFLLFLLLLPPLP", ["M"]) == 5
assert get_multi_aa_res("MSRSLLLRFLLFLLLLPPLP", ['M', 'L']) == 55
assert get_multi_aa_res("MSRSLLLRFLLFLLLLPPLP", ['F', 'S', 'L']) == 70
assert get_multi_aa_res("MSRSLLLRFLLFLLLLPPLP") == 65
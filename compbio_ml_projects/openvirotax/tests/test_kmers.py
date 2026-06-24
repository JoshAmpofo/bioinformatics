"""Tests for k-mer featurization contracts."""
import numpy as np
import pytest

from src.features.kmers import (
    gc_content,
    kmer_frequencies,
    kmer_vocabulary,
)


def test_vocab_size_is_four_to_the_k():
    assert len(kmer_vocabulary(4)) == 4 ** 4 == 256
    assert len(kmer_vocabulary(1)) == 4


def test_frequencies_sum_to_one():
    vocab = kmer_vocabulary(4)
    vec = kmer_frequencies("ACGT" * 50, k=4, vocab=vocab)
    assert pytest.approx(vec.sum(), abs=1e-5) == 1.0


def test_short_sequence_gives_zero_vector():
    vocab = kmer_vocabulary(4)
    vec = kmer_frequencies("AC", k=4, vocab=vocab)  # shorter than k
    assert vec.sum() == 0.0
    assert vec.shape == (256,)


def test_known_kmer_lands_in_right_bin():
    vocab = kmer_vocabulary(2)
    vec = kmer_frequencies("AAAA", k=2, vocab=vocab)  # only "AA", 3 windows
    assert vec[vocab["AA"]] == pytest.approx(1.0)


def test_gc_content():
    assert gc_content("GCGC") == 1.0
    assert gc_content("ATAT") == 0.0
    assert gc_content("") == 0.0


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))

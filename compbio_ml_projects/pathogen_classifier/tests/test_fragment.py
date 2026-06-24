"""Tests for the fragmentation step.

These check the *contract* of ``sample_fragments`` — properties any correct
sampling strategy must satisfy — so they pass whether you choose random-start,
tiling, or length-weighted sampling.
"""
import random

import pytest

from src.data_processing.fragment import (
    Fragment,
    clean_sequence,
    fragment_genome,
    sample_fragments,
)

GENOME = "ACGT" * 500  # 2000 bp toy genome


def test_fragments_have_exact_length():
    rng = random.Random(0)
    frags = sample_fragments(GENOME, frag_length=250, rng=rng, n_per_genome=10)
    assert frags, "should produce at least one fragment from a 2000bp genome"
    for sub, start in frags:
        assert len(sub) == 250
        assert GENOME[start:start + 250] == sub  # start index must be truthful


def test_no_fragments_when_genome_too_short():
    rng = random.Random(0)
    assert sample_fragments("ACGT", frag_length=250, rng=rng, n_per_genome=5) == []


def test_sampling_is_reproducible_with_seed():
    a = sample_fragments(GENOME, 250, random.Random(42), 10)
    b = sample_fragments(GENOME, 250, random.Random(42), 10)
    assert a == b, "same seed must give identical fragments (reproducibility)"


def test_fragment_genome_keeps_full_length_sentinel():
    rng = random.Random(0)
    frags = fragment_genome(GENOME, "ACC1", "Coronaviridae",
                            frag_lengths=[0, 250], rng=rng, n_per_genome=5)
    full = [f for f in frags if f.frag_length == 0]
    assert len(full) == 1
    assert full[0].seq == GENOME  # length 0 means "keep whole genome"
    assert all(isinstance(f, Fragment) for f in frags)


def test_clean_sequence_strips_non_acgt():
    assert clean_sequence("acgtN-RYacgt") == "ACGTACGT"


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))

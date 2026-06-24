"""Slice whole genomes into short fragments to mimic metagenome contigs.

Real metagenomic assemblies rarely give you a complete genome — they give you
broken contigs of a few hundred to a few thousand bp. To evaluate a classifier
*honestly* for that setting, we must train/test it on fragments, not on the tidy
full-length RefSeq records.

This module turns each genome into fragments at several target lengths
{full, 1000, 500, 250}. The heart of it — how we *sample* fragment start
positions — is a genuine scientific choice left to you (see ``sample_fragments``).
"""
from __future__ import annotations

import random
from dataclasses import dataclass


@dataclass(frozen=True)
class Fragment:
    """One simulated contig drawn from a source genome."""
    seq: str
    source_accession: str
    family: str
    frag_length: int   # the *target* length bucket (e.g. 250); "full" -> 0
    start: int


# ──────────────────────────────────────────────────────────────────────────
# 🧠 YOUR CODE — Decision #1: the fragment-sampling strategy
# ──────────────────────────────────────────────────────────────────────────
def sample_fragments(
    seq: str,
    frag_length: int,
    rng: random.Random,
    n_per_genome: int,
) -> list[tuple[str, int]]:
    """Draw fragments of ``frag_length`` bp from a single genome ``seq``.

    This is the core decision of the fragmentation step. You choose HOW the
    "messy metagenome" is simulated. Return a list of ``(subsequence, start)``
    tuples. The scaffolding around you handles labels, families, and the
    multi-length sweep — you only decide the sampling.

    Args:
        seq:           The full genome sequence (a string of ACGT...).
        frag_length:   Target fragment length in bp (e.g. 250, 500, 1000).
        rng:           A seeded ``random.Random`` — USE THIS for any randomness
                       (do not call ``random.*`` directly) so runs reproduce.
        n_per_genome:  Suggested number of fragments to draw from this genome.

    Returns:
        List of ``(fragment_sequence, start_index)``. Each fragment should be
        exactly ``frag_length`` bp (drop or skip any that can't be).

    ─── Design choices to weigh (pick one and justify it in a comment) ───
      • Random-start windows: draw ``n_per_genome`` random start positions in
        ``[0, len(seq) - frag_length]``. Simple; samples the genome unevenly;
        a region can be covered twice or not at all. Mirrors random shearing.
      • Non-overlapping tiling: cut the genome into back-to-back windows
        (0, L, 2L, ...). Even coverage, deterministic count = len(seq)//L,
        ignores ``n_per_genome``. Mirrors clean tiling/assembly.
      • Length-weighted: draw more fragments from longer genomes so each *base*
        is equally likely — prevents a 28kb coronavirus and a 2kb flu segment
        from contributing the same number of training fragments.

    Why it matters: this shapes class balance after fragmentation (segmented
    families like influenza yield far fewer fragments per record) and how
    representative the simulated contigs are of a real metagenome.

    A correct, minimal placeholder is provided so the pipeline runs; REPLACE it
    with your chosen strategy.
    """
    # Chosen strategy: LENGTH-WEIGHTED RANDOM sampling.
    # The number of fragments tracks genome length (~1x coverage), so each base
    # is equally likely to be sampled across genomes of very different sizes.
    # Starts are random (not tiled) to mimic random shearing of a metagenome.
    fragments: list[tuple[str, int]] = []
    if frag_length <= 0 or len(seq) < frag_length:
        return fragments
    max_start = len(seq) - frag_length
    # Count ∝ length: a genome k fragment-lengths long yields ~k fragments.
    # n_per_genome acts only as a generous safety cap to bound dataset size.
    n_fragments = max(1, round(len(seq) / frag_length))
    n_fragments = min(n_fragments, n_per_genome)
    for _ in range(n_fragments):
        start = rng.randint(0, max_start)
        fragments.append((seq[start:start + frag_length], start))
    return fragments
# ──────────────────────────────────────────────────────────────────────────


def fragment_genome(
    seq: str,
    accession: str,
    family: str,
    frag_lengths: list[int],
    rng: random.Random,
    n_per_genome: int = 20,
) -> list[Fragment]:
    """Produce fragments for one genome across all requested length buckets.

    ``frag_length == 0`` is the sentinel for "keep the full genome" (no slicing),
    so the benchmark can compare full-length vs fragmented performance.
    """
    out: list[Fragment] = []
    for fl in frag_lengths:
        if fl == 0:  # full-length: the genome itself is the single "fragment"
            out.append(Fragment(seq, accession, family, 0, 0))
            continue
        for sub, start in sample_fragments(seq, fl, rng, n_per_genome):
            out.append(Fragment(sub, accession, family, fl, start))
    return out


def clean_sequence(seq: str) -> str:
    """Uppercase and strip non-ACGT characters (N's, gaps, ambiguity codes)."""
    seq = seq.upper()
    return "".join(c for c in seq if c in "ACGT")

"""Turn DNA fragments into fixed-length k-mer frequency vectors.

A classifier needs fixed-width numeric input, but fragments vary in length. We
slide a window of size ``k`` over each sequence, count every k-mer, and normalize
to frequencies — giving a ``4**k``-dim vector (k=4 -> 256) for any input length.
Different viral families carry different k-mer signatures (codon/dinucleotide
bias), which is the signal the downstream model learns.

We also append GC content as one extra feature (config: features.compositional).
"""
from __future__ import annotations

from itertools import product

import numpy as np
import pandas as pd

from src.config import get_paths, load_config

_ALPHABET = "ACGT"


def kmer_vocabulary(k: int) -> dict[str, int]:
    """All 4**k canonical k-mers mapped to a stable column index."""
    return {"".join(p): i for i, p in enumerate(product(_ALPHABET, repeat=k))}


def kmer_frequencies(seq: str, k: int, vocab: dict[str, int]) -> np.ndarray:
    """Normalized k-mer frequency vector for one sequence (sums to ~1).

    Unknown k-mers (containing non-ACGT after cleaning shouldn't occur, but
    short sequences can yield zero windows) produce an all-zero vector.
    """
    vec = np.zeros(len(vocab), dtype=np.float32)
    n_windows = len(seq) - k + 1
    if n_windows <= 0:
        return vec
    for i in range(n_windows):
        idx = vocab.get(seq[i:i + k])
        if idx is not None:
            vec[idx] += 1.0
    total = vec.sum()
    if total > 0:
        vec /= total
    return vec


def gc_content(seq: str) -> float:
    """Fraction of G/C bases — a classic compositional discriminator."""
    if not seq:
        return 0.0
    return (seq.count("G") + seq.count("C")) / len(seq)


def featurize(df: pd.DataFrame, k: int, with_gc: bool = True) -> tuple[np.ndarray, list[str]]:
    """Vectorize a fragments DataFrame into an (n_samples, n_features) matrix.

    Returns the feature matrix and the list of feature names (k-mers [+ 'gc']).
    """
    vocab = kmer_vocabulary(k)
    feats = np.zeros((len(df), len(vocab) + (1 if with_gc else 0)), dtype=np.float32)
    for row_i, seq in enumerate(df["seq"].to_numpy()):
        feats[row_i, :len(vocab)] = kmer_frequencies(seq, k, vocab)
        if with_gc:
            feats[row_i, len(vocab)] = gc_content(seq)
    names = list(vocab.keys()) + (["gc"] if with_gc else [])
    return feats, names


def build_features(cfg: dict, k: int | None = None) -> None:
    """Featurize the materialized fragments and cache matrix + labels to disk."""
    paths = get_paths(cfg)
    k = k or cfg["data"]["sequence"]["kmer_size"]
    df = pd.read_parquet(paths["processed"] / "fragments.parquet")

    X, names = featurize(df, k)
    np.save(paths["processed"] / f"X_k{k}.npy", X)
    # Carry labels + grouping/length columns alongside the matrix (row-aligned).
    df[["family", "frag_length", "source_accession"]].to_parquet(
        paths["processed"] / "labels.parquet", index=False
    )
    with open(paths["processed"] / f"feature_names_k{k}.txt", "w") as fh:
        fh.write("\n".join(names))
    print(f"Features: X_k{k}.npy shape={X.shape} ({len(names)} cols, GC included)")


def main() -> None:
    cfg = load_config()
    # k=4 (256 dims) is a good fragment-friendly default; config default is 6.
    build_features(cfg, k=4)


if __name__ == "__main__":
    main()

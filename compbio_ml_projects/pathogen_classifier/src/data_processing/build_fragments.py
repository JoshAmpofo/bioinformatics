"""Build the fragment dataset from downloaded genomes.

Loads every genome under ``data/raw/<Family>/*.fasta``, cleans it, applies the
length-weighted ``sample_fragments`` strategy across the configured fragment
lengths, and writes one tidy table:

    data/processed/fragments.parquet   (columns: seq, family, frag_length,
                                         source_accession, start)

Keeping fragmentation as a materialized artifact (not recomputed each run) means
features, calibration, and the benchmark all read the *same* fragments — a
prerequisite for the family-disjoint splits the project depends on.

Run:
    python -m src.data_processing.build_fragments
"""
from __future__ import annotations

import random

import pandas as pd
from Bio import SeqIO

from src.config import get_paths, load_config, target_families
from src.data_processing.fragment import clean_sequence, fragment_genome

# 0 is the "keep full genome" sentinel; the rest mimic metagenome contig sizes.
FRAG_LENGTHS = [0, 1000, 500, 250]
SEED = 42
# Safety cap on fragments per (genome, length); length-weighting picks fewer.
N_PER_GENOME_CAP = 200


def build(cfg: dict) -> pd.DataFrame:
    paths = get_paths(cfg)
    rng = random.Random(SEED)

    records = []
    for family in target_families(cfg):
        fam_dir = paths["raw"] / family
        if not fam_dir.exists():
            continue
        for fasta in fam_dir.glob("*.fasta"):
            rec = next(SeqIO.parse(fasta, "fasta"), None)
            if rec is None:
                continue
            seq = clean_sequence(str(rec.seq))
            for frag in fragment_genome(
                seq, fasta.stem, family, FRAG_LENGTHS, rng,
                n_per_genome=N_PER_GENOME_CAP,
            ):
                records.append({
                    "seq": frag.seq,
                    "family": frag.family,
                    "frag_length": frag.frag_length,
                    "source_accession": frag.source_accession,
                    "start": frag.start,
                })

    df = pd.DataFrame.from_records(records)
    out = paths["processed"] / "fragments.parquet"
    df.to_parquet(out, index=False)
    print(f"Wrote {len(df):,} fragments -> {out}")
    print(df.groupby(["family", "frag_length"]).size().unstack(fill_value=0))
    return df


def main() -> None:
    build(load_config())


if __name__ == "__main__":
    main()

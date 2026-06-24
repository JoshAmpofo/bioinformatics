"""Download complete RefSeq viral genomes from NCBI, by family.

This implements the empty ``Dataloader.download_data()`` hook. For each target
family in the config it runs an Entrez search restricted to RefSeq complete
genomes, fetches FASTA in batches, and writes:

    data/raw/<Family>/<accession>.fasta
    data/metadata.csv          (accession, family, length, description)

Design notes (this is the only step that touches the network):
  * NCBI allows ~3 requests/sec without an API key; we sleep between calls.
  * Every network call is wrapped in a bounded retry with backoff.
  * ``per_family`` caps each class so the dataset stays balanced and small.
  * Start with a tiny cap (smoke test) before pulling thousands.

Run:
    python -m src.data_processing.download --per-family 5      # smoke test
    python -m src.data_processing.download --per-family 600    # full pull
"""
from __future__ import annotations

import argparse
import csv
import time
from pathlib import Path

from Bio import Entrez, SeqIO

from src.config import get_paths, load_config, target_families

# Be a good NCBI citizen: identify ourselves and throttle.
_REQUEST_PAUSE = 0.4  # seconds between Entrez calls (~2.5/sec, under the 3/sec cap)
_MAX_RETRIES = 4
_FETCH_BATCH = 100  # accessions per efetch call


def _entrez_call(func, **kwargs):
    """Call an Entrez function with bounded retries + exponential backoff."""
    last_err = None
    for attempt in range(_MAX_RETRIES):
        try:
            handle = func(**kwargs)
            time.sleep(_REQUEST_PAUSE)
            return handle
        except Exception as err:  # network/HTTP/parse errors from NCBI
            last_err = err
            wait = _REQUEST_PAUSE * (2 ** attempt)
            print(f"  [retry {attempt + 1}/{_MAX_RETRIES}] {type(err).__name__}: {err} "
                  f"-> sleeping {wait:.1f}s")
            time.sleep(wait)
    raise RuntimeError(f"Entrez call failed after {_MAX_RETRIES} retries: {last_err}")


def _search_family(family: str, retmax: int, min_len: int, max_len: int) -> list[str]:
    """Return up to ``retmax`` RefSeq nucleotide accessions for a viral family."""
    # srcdb_refseq[PROP] = RefSeq curated records; sequence length bounds keep us
    # to genome-scale records and drop stray fragments/segments noise.
    query = (
        f'"{family}"[Organism] AND srcdb_refseq[PROP] '
        f'AND {min_len}:{max_len}[Sequence Length]'
    )
    handle = _entrez_call(Entrez.esearch, db="nucleotide", term=query, retmax=retmax)
    record = Entrez.read(handle)
    handle.close()
    return record["IdList"]


def _fetch_fasta(accessions: list[str]):
    """Yield SeqRecords for a list of accessions, fetched in batches."""
    for start in range(0, len(accessions), _FETCH_BATCH):
        batch = accessions[start:start + _FETCH_BATCH]
        handle = _entrez_call(
            Entrez.efetch, db="nucleotide", id=",".join(batch),
            rettype="fasta", retmode="text",
        )
        for record in SeqIO.parse(handle, "fasta"):
            yield record
        handle.close()


def download_data(cfg: dict, per_family: int = 600) -> Path:
    """Download genomes for all target families and write metadata.csv.

    Returns the path to the metadata CSV.
    """
    Entrez.email = cfg["external_apis"]["ncbi"]["email"]
    paths = get_paths(cfg)
    seq_cfg = cfg["data"]["sequence"]
    min_len, max_len = seq_cfg["min_length"], seq_cfg["max_length"]

    rows: list[dict] = []
    for family in target_families(cfg):
        print(f"\n=== {family} (cap {per_family}) ===")
        fam_dir = paths["raw"] / family
        fam_dir.mkdir(parents=True, exist_ok=True)

        accessions = _search_family(family, per_family, min_len, max_len)
        print(f"  found {len(accessions)} accessions")

        kept = 0
        for record in _fetch_fasta(accessions):
            seq_len = len(record.seq)
            if not (min_len <= seq_len <= max_len):
                continue
            acc = record.id.split(".")[0]  # strip version suffix
            (fam_dir / f"{acc}.fasta").write_text(record.format("fasta"))
            rows.append({
                "accession": acc,
                "family": family,
                "length": seq_len,
                "description": record.description[:120],
            })
            kept += 1
        print(f"  saved {kept} genomes")

    _write_metadata(paths["metadata"], rows)
    print(f"\nTotal: {len(rows)} genomes across {len(target_families(cfg))} families")
    print(f"Metadata -> {paths['metadata']}")
    return paths["metadata"]


def _write_metadata(path: Path, rows: list[dict]) -> None:
    with open(path, "w", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=["accession", "family", "length", "description"]
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Download RefSeq viral genomes by family.")
    parser.add_argument("--per-family", type=int, default=600,
                        help="Max genomes per family (use a small value to smoke-test).")
    args = parser.parse_args()
    cfg = load_config()
    download_data(cfg, per_family=args.per_family)


if __name__ == "__main__":
    main()

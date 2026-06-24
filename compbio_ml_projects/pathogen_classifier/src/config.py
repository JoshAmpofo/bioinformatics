"""Shared configuration + path helpers for the OpenViroTax pipeline.

Every module loads settings through here so that knobs (k-mer size, families,
fragment lengths, splits) live in one place: ``config/config.yaml``. This mirrors
the project's existing config-driven design instead of hard-coding constants.
"""
from __future__ import annotations

import os
from pathlib import Path

import yaml

# Project root = the pathogen_classifier/ directory (two levels up from this file).
ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "config" / "config.yaml"


def load_config(path: str | os.PathLike | None = None) -> dict:
    """Load the YAML config as a plain dict.

    Args:
        path: Optional override; defaults to ``config/config.yaml``.

    Returns:
        Parsed configuration dictionary.
    """
    cfg_path = Path(path) if path else CONFIG_PATH
    with open(cfg_path, "r") as handle:
        return yaml.safe_load(handle)


def get_paths(cfg: dict) -> dict[str, Path]:
    """Resolve the directory layout to absolute paths and create them.

    Centralizing this means no module has to guess where ``data/raw`` lives or
    remember to ``mkdir`` before writing.
    """
    raw = ROOT / cfg["data"]["raw_data_dir"]
    processed = ROOT / cfg["data"]["processed_data_dir"]
    results = ROOT / "results"
    paths = {
        "root": ROOT,
        "raw": raw,
        "processed": processed,
        "results": results,
        "metadata": raw.parent / "metadata.csv",
    }
    for key in ("raw", "processed", "results"):
        paths[key].mkdir(parents=True, exist_ok=True)
    return paths


def target_families(cfg: dict) -> list[str]:
    """The viral families we classify, in a fixed canonical order."""
    return list(cfg["classes"]["target_families"])

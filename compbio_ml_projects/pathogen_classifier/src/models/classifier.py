"""Baseline viral-family classifier + probability calibration.

Pipeline:
  1. Load cached k-mer features (row-aligned with labels.parquet).
  2. Split FAMILY-DISJOINT BY ACCESSION so no genome leaks across train/test —
     fragments of one genome share k-mers; splitting by fragment would inflate
     accuracy through leakage.
  3. Train a base classifier with class_weight="balanced" (handles the ~6.5x
     fragment imbalance without distorting the data).
  4. Calibrate its probabilities (your decision: isotonic vs sigmoid).
  5. Report balanced accuracy + Expected Calibration Error (ECE) before/after.

ECE measures *honesty*: of all predictions made with ~80% confidence, do ~80%
turn out correct? A low ECE means the probabilities can be trusted for the
abstention step that follows.
"""
from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import balanced_accuracy_score
from sklearn.model_selection import GroupShuffleSplit

from src.config import get_paths, load_config


def load_xy(cfg: dict, k: int = 4, frag_length: int | None = None):
    """Load features X, labels y, and group ids (accessions).

    If ``frag_length`` is given, restrict to that fragment bucket so we can
    evaluate per-contig-length (e.g. only 250 bp fragments).
    """
    paths = get_paths(cfg)
    X = np.load(paths["processed"] / f"X_k{k}.npy")
    labels = pd.read_parquet(paths["processed"] / "labels.parquet")
    if frag_length is not None:
        mask = (labels["frag_length"] == frag_length).to_numpy()
        X, labels = X[mask], labels[mask].reset_index(drop=True)
    y = labels["family"].to_numpy()
    groups = labels["source_accession"].to_numpy()
    return X, y, groups


def family_disjoint_split(X, y, groups, test_size=0.25, seed=42):
    """Train/test split where whole genomes (accessions) never cross the line."""
    splitter = GroupShuffleSplit(n_splits=1, test_size=test_size, random_state=seed)
    train_idx, test_idx = next(splitter.split(X, y, groups))
    return train_idx, test_idx


def expected_calibration_error(y_true, proba, classes, n_bins=10) -> float:
    """Multi-class ECE via confidence binning of the top-1 prediction.

    Bins predictions by their max probability; in each bin compares mean
    confidence to actual accuracy; ECE is the sample-weighted average gap.
    """
    conf = proba.max(axis=1)
    pred = classes[proba.argmax(axis=1)]
    correct = (pred == y_true).astype(float)
    bins = np.linspace(0.0, 1.0, n_bins + 1)
    ece = 0.0
    for lo, hi in zip(bins[:-1], bins[1:]):
        in_bin = (conf > lo) & (conf <= hi)
        if in_bin.sum() == 0:
            continue
        ece += (in_bin.mean()) * abs(correct[in_bin].mean() - conf[in_bin].mean())
    return float(ece)


# ──────────────────────────────────────────────────────────────────────────
# 🧠 YOUR CODE — Decision #2: which calibration method?
# ──────────────────────────────────────────────────────────────────────────
def pick_calibrator(base_estimator, n_per_class_min: int):
    """Wrap ``base_estimator`` in a CalibratedClassifierCV with YOUR method.

    Return a ``CalibratedClassifierCV(base_estimator, method=..., cv=...)``.

    ─── The trade-off ───
      • method="isotonic": non-parametric, flexible — can correct any monotonic
        miscalibration shape. BUT it is data-hungry; with few samples per class
        it overfits the calibration set. Rule of thumb: prefer when each class
        has a few-thousand+ calibration points.
      • method="sigmoid" (Platt): fits a 2-parameter logistic. Robust on small
        data, but can only correct sigmoid-shaped miscalibration.
      • cv: number of internal calibration folds (e.g. 3-5). More folds = more
        stable calibration but slower.

    Context for your choice: our smallest class is Filoviridae (~4% of the pool;
    ~1112 fragments at 250 bp, fewer after the train split). ``n_per_class_min``
    is passed in so you can branch on it if you like.

    A working placeholder (sigmoid) is provided — REPLACE it with your reasoned
    choice and a one-line comment explaining why.
    """
    # Adaptive (best of both worlds): use flexible isotonic when even the
    # smallest class has enough calibration points to support it; fall back to
    # robust sigmoid when a rare class (e.g. Filoviridae) would make isotonic
    # overfit. Threshold 1000 ~ the point where isotonic's step function has
    # enough samples per class to be stable.
    method = "isotonic" if n_per_class_min >= 1000 else "sigmoid"
    return CalibratedClassifierCV(base_estimator, method=method, cv=5)
# ──────────────────────────────────────────────────────────────────────────


def train_and_evaluate(cfg: dict, k: int = 4, frag_length: int = 250, seed: int = 42):
    """End-to-end: split, train base, calibrate, report ECE before/after."""
    X, y, groups = load_xy(cfg, k=k, frag_length=frag_length)
    tr, te = family_disjoint_split(X, y, groups, seed=seed)

    base = RandomForestClassifier(
        n_estimators=200, class_weight="balanced", n_jobs=-1, random_state=seed,
    )
    base.fit(X[tr], y[tr])
    classes = base.classes_

    proba_raw = base.predict_proba(X[te])
    ece_raw = expected_calibration_error(y[te], proba_raw, classes)
    bacc = balanced_accuracy_score(y[te], classes[proba_raw.argmax(1)])

    counts = pd.Series(y[tr]).value_counts()
    calibrated = pick_calibrator(
        RandomForestClassifier(n_estimators=200, class_weight="balanced",
                               n_jobs=-1, random_state=seed),
        n_per_class_min=int(counts.min()),
    )
    calibrated.fit(X[tr], y[tr])
    proba_cal = calibrated.predict_proba(X[te])
    ece_cal = expected_calibration_error(y[te], proba_cal, calibrated.classes_)

    print(f"[frag_length={frag_length}]  balanced_acc={bacc:.3f}")
    print(f"  ECE raw       = {ece_raw:.4f}")
    print(f"  ECE calibrated= {ece_cal:.4f}  ({'better' if ece_cal < ece_raw else 'worse'})")
    return {"balanced_acc": bacc, "ece_raw": ece_raw, "ece_cal": ece_cal}


def main() -> None:
    train_and_evaluate(load_config())


if __name__ == "__main__":
    main()

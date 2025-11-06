## Small CLI utilities

A compact collection of Python scripts useful for common sequence-processing tasks. These utilities are intended for quick, local use in bioinformatics workflows (alignment checks, quick QA, learning and prototyping).

This repository currently contains a small command-line tool to detect base changes between two nucleotide (or amino-acid) sequences.

## Scripts

- [mutant_detector](mutant_detector.py) — Compare two sequences and report any base substitutions (positions and changes).

## mutant_detector.py — what it does

Given two sequences (the reference/original sequence and a mutated/observed sequence), the script scans them position-by-position and reports any substitutions it finds. It prints the 1-based position, the original base, and the mutated base for each difference.

Notes:
- Sequences are compared left-to-right. The script expects sequences to be the same length; any length differences are reported as an error.
- Indexing is 1-based (first base is position 1).

## Quick usage

Make the script executable (if needed) and run it with two sequences on the command line:

```bash
chmod +x mutant_detector.py
./mutant_detector.py ORIGINAL_SEQ MUTANT_SEQ
```

Example:

```bash
./mutant_detector.py ATGCCGT ATGACGT
# Output:
# Mutation found at position 4: C -> A
```

If there are multiple mutations, each will be printed on its own line:

```bash
./mutant_detector.py ATGCCGT ATGTCGA
# Mutation found at position 4: C -> T
# Mutation found at position 7: T -> A
```

If the sequences are different lengths, the script will report an error and exit with a non-zero status.

## Requirements

- Python 3.7+ (recommended 3.8+). The script uses only the standard library so there are no extra pip requirements.

## Examples and testing

You can test the script quickly from the shell using short sequences as shown above.

## Troubleshooting

- If you see no output, there were no substitutions detected (the sequences are identical).
- If you see a length error, verify you provided two sequences of equal length. If you need to compare sequences with indels, consider aligning them first (outside this script).

## Contributing

Small contributions are welcome. Ideas:

- Add support for FASTA input files (path or stdin) and sequence parsing.
- Add support for reporting insertions/deletions (requires sequence alignment handling).
- Add unit tests and CI (GitHub Actions).

When contributing, please follow these small rules:

1. Open an issue describing the change first for larger features.
2. Keep changes minimal and add tests for new behavior.

## License

MIT.

## Contact

### Maintainer: Josh Ampofo

### ampofojoshuayent@gmail.com
---


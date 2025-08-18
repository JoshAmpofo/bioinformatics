# Sequence Length Calculator

A Python script that calculates the length of DNA sequences from FASTA files using the Biopython library.

## Description

This tool parses FASTA files containing DNA sequences and calculates the length of each sequence. It's useful for bioinformatics workflows where you need to quickly determine the size of multiple DNA sequences (check the example folder for a multi-sequence fasta file to use to test the script).

## Features

- Parse FASTA files with multiple sequences
- Calculate sequence lengths efficiently
- Handle multiple sequence IDs in a single file
- Provide clear error messages for file issues
- Command-line interface for easy integration into workflows

## Installation

### Prerequisites

- Python 3.6 or higher
- Biopython library

### Install Dependencies

```bash
pip install biopython
```

## Usage

### Command Line Interface

```bash
python seq_length.py -f <fasta_file>
```

### Arguments

- `-f, --fasta`: Path to the input FASTA file (required)

### Examples

```bash
# Basic usage
python seq_length.py -f sequences.fasta

# Using long form argument
python seq_length.py --fasta input.fa

# Get help
python seq_length.py --help
```

## Function Documentation

### `calculate_sequence_length(fasta_file)`

Calculates the length of DNA sequences from a FASTA file.

#### Parameters

- **fasta_file** (`str`): Path to the FASTA file containing DNA sequences

#### Returns

- **dict**: Dictionary with sequence ID as key and sequence length as value
- **None**: If an error occurs (file not found or parsing error)

#### Example

```python
from seq_length import calculate_sequence_length

# Calculate lengths
results = calculate_sequence_length("sequences.fasta")

# Process results
if results:
    for seq_id, length in results.items():
        print(f"Sequence {seq_id}: {length} bp")
else:
    print("Error processing file")
```

## Input Format

The script expects FASTA format files with the following structure:

```
>sequence_id_1
ATCGATCGATCGATCGATCG
>sequence_id_2
GCTAGCTAGCTAGCTAGCTA
```

## Output Format

The script outputs each sequence ID followed by its length:

```
sequence_id_1: 20
sequence_id_2: 20
```

## Error Handling

The script handles several error conditions:

- **File not found**: Displays an error message and exits
- **Invalid FASTA format**: Displays parsing errors
- **Missing arguments**: Shows usage information and help

## Example FASTA File

Create a file named `example.fasta`:

```
>seq1
ATCGATCGATCGATCGATCG
>seq2
GCTAGCTAGCTAGCTAGCTA
>seq3
TAGCTAGCTAGCTAGCTAGC
```

Run the script:

```bash
python seq_length.py -f example.fasta
```

Expected output:

```
seq1: 20
seq2: 20
seq3: 20
```

## Dependencies

- **Biopython**: For FASTA file parsing and sequence handling
- **argparse**: For command-line argument parsing (built-in)

## License

This project is licensed under the MIT License

## Issues

If you encounter any issues, please check:

1. The FASTA file exists and is readable
2. The file is in valid FASTA format
3. You have the required dependencies installed

## Version

Current version: 1.0.0

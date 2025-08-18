#!/usr/bin/env python3

"""
This simple script calculates the length of a sequence of DNA when given an input FASTA file.
It uses the Biopython library to parse the FASTA file and calculate the length of the sequence.
"""
import argparse
from Bio import SeqIO


def validate_fasta_file(filepath):
    if not filepath.endswith((".fasta", ".fa", ".fas")):
        print(
            f"Warning: {filepath} doesn't have a .fasta, .fa, or .fas extension. Please check the file extension."
        )
    return filepath


parser = argparse.ArgumentParser(
    description="Calculate the length of a sequence of DNA when given an input FASTA file.",
    usage="%(prog)s -f </path/to/sequences.fasta>",
    epilog="python seq_length.py -f /path/to/sequence.fasta",
)

parser.add_argument(
    "-f",
    "--fasta",
    required=True,
    help="path to the input FASTA file",
    metavar="FASTA_FILE",
    type=validate_fasta_file,
)


def calculate_sequence_length(fasta_file):
    """
    calculates the length of a DNA sequence from a FASTA file

    Args:
        fasta_file (str): path to the FASTA file

    Returns:
        dict: dictionary with sequence id as key and length as value
    """
    # set dict to hold sequence length and id
    sequence_lengths = {}

    # open FASTA file and parse fasta file, selecting id, seq
    try:
        with open(fasta_file, "r") as handle:
            for record in SeqIO.parse(handle, "fasta"):
                sequence_id = record.id
                sequence = record.seq
                sequence_length = len(sequence)
                sequence_lengths[sequence_id] = sequence_length
            return sequence_lengths
    except FileNotFoundError:
        print('No file found. Please check filepath.')
        return None


def print_sequence_lengths(sequence_lengths):
    """
    prints the sequence lengths to the console

    Args:
        sequence_lengths (dict): dictionary with sequence id as key and length as value
    """
    for sequence_id, sequence_length in sequence_lengths.items():
        print(f"{sequence_id}: {sequence_length:,} bp")


if __name__ == "__main__":
    try:
        args = parser.parse_args()
    except SystemExit:
        parser.print_help()
        exit(1)

    fasta_file = args.fasta
    sequence_lengths = calculate_sequence_length(fasta_file)
    if sequence_lengths is None:
        exit(1)
        
    print_sequence_lengths(sequence_lengths)

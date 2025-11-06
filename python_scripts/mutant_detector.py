#!/usr/bin/env python3


import argparse


def mutation_position_detector(original_seq: str, mutated_seq: str) -> int:
    """
    Reads two sequences and returns the position and base letter of the mutation.
    
    Args:
        original_seq (str): The original DNA sequence.
        mutated_seq (str): The mutated DNA sequence.
    
    Returns:
        int: The position of the mutation (1-based index).
    """
    # clean sequences by removing whitespace and converting to uppercase
    original_seq = original_seq.replace(" ", "").upper()
    mutated_seq = mutated_seq.replace(" ", "").upper()
    
    # some basic validation here
    try:
        if len(original_seq) != len(mutated_seq):
            raise ValueError("Sequences must be of equal length.")

    except ValueError as e:
        print(f"Error: {e}")
        return -1

    # main mutation position finding logic
    for position in range(len(original_seq)):
        if original_seq[position] != mutated_seq[position]:
            print(f"Mutation found at position {position + 1}: {original_seq[position]} -> {mutated_seq[position]}")
            return position + 1  # Return 1-based index
    print("No mutation found.")
    return -1  # Indicate no mutation found

# orchestration for command-line execution
def main():
    parser = argparse.ArgumentParser(
        description="Detects the position of a mutation between two DNA sequences."
    )
    parser.add_argument(
        "original_seq",
        type=str,
        help="The original DNA sequence."
    )
    parser.add_argument(
        "mutated_seq",
        type=str,
        help="The mutated DNA sequence."
    )
    args = parser.parse_args()

    mutation_position_detector(args.original_seq, args.mutated_seq)

    
if __name__ == "__main__":
    main()

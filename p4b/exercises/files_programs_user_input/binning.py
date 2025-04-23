#!/usr/bin/env python3

"""
Write a program which creates nine new folders - one for sequences between 100 and 199 bases long
- one for sequences between 200 and 299 bases long, etc.
Write out eacch DNA sequence in the input files to a separate file in the appropriate folder.

Your program will have to:
    - iterate over the files in the folder
    - iterate over the lines in each file
    - figure out which bon eacch DNA sequence should go in based on its length
    - write out each DNA sequence to a new file in the right folder
"""

import os
import re

def create_bin_folders(base_dir):
    """Create 9 folders for different sequence length ranges."""
    for i in range(1, 10):
        start = i * 100
        end = start + 99
        folder_name = f"{start}-{end}"
        folder_path = os.path.join(base_dir, folder_name)
        os.makedirs(folder_path, exist_ok=True)


def get_sequence_length(sequence):
    """Calculate the length of a DNA sequence, ignoring any non-DNA characters."""
    # Remove any whitespace and non-DNA characters
    clean_sequence = re.sub(r'[^ACGT]', '', sequence.upper())
    return len(clean_sequence)


def get_bin_folder(length):
    """Determine which bin folder a sequence of given length belongs to."""
    bin_number = (length // 100) + 1
    if bin_number > 9:  # Handle sequences longer than 999
        bin_number = 9
    start = (bin_number * 100)
    end = start + 99
    return f"{start}-{end}"


def process_dna_files(input_dir, output_dir):
    """Process all .dna files in the input directory and bin sequences by length."""
    # Create the bin folders
    create_bin_folders(output_dir)
    
    # Process each .dna file in the input directory
    for filename in os.listdir(input_dir):
        if filename.endswith('.dna'):
            file_path = os.path.join(input_dir, filename)
            base_name = os.path.splitext(filename)[0]
            
            # Read and process each sequence in the file
            with open(file_path, 'r') as file:
                for line_number, line in enumerate(file, 1):
                    sequence = line.strip()
                    if not sequence:  # Skip empty lines
                        continue
                        
                    length = get_sequence_length(sequence)
                    bin_folder = get_bin_folder(length)
                    
                    # Create a unique filename for each sequence
                    output_filename = f"{base_name}_seq{line_number}_{length}bp.dna"
                    output_path = os.path.join(output_dir, bin_folder, output_filename)
                    
                    # Write the sequence to the appropriate bin folder
                    with open(output_path, 'w') as out_file:
                        out_file.write(sequence)


if __name__ == "__main__":
    # Example usage
    input_directory = "../../exercises and examples/working_with_the_filesystem/exercises/"
    output_directory = "binned_sequences"
    
    # Create the output directory if it doesn't exist
    os.makedirs(output_directory, exist_ok=True)
    
    # Process the files
    process_dna_files(input_directory, output_directory)

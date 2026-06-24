"""
This script handles the loading and preprocessing of genomic data for the pathogen classifier.
"""
import os
from Bio import Entrez
from Bio import SeqIO

class Dataloader:
    """
    loads downloaded viral genome data for preprocessing
    """
    def __init__(self, config):
        self.config = config
    
    def download_data(self):
        pass

    def load_data(self):
        """main method to load data in different formats (.fasta, .fa, .gbk)"""
        # connect to raw data location
        raw_data_path = self.config['data']['raw_data_dir']
        
        # load sequence files from this directory
        sequences = []
        
        # fasta files
        for file in os.listdir(raw_data_path):
            if file.endswith('.fasta') or file.endswith('.fa'):
                # open dir 
                with open(os.path.join(raw_data_path, file), "r") as handle:
                    for record in SeqIO.parse(handle, "fasta"):
                        sequences.append(record)
            # genbank files
            elif file.endswith('.gb') or file.endswith('.gbk'):
                with open(os.path.join(raw_data_path, file), "r") as handle:
                    for record in SeqIO.parse(handle, 'genbank'):
                        sequences.append(record)
        
        return sequences
        
        
        
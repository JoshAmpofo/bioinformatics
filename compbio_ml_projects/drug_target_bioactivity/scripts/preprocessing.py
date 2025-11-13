#!/usr/bin/env python3

import numpy as np
from rdkit import Chem
from rdkit.Chem import Descriptors, AllChem
from rdkit.Chem import rdFingerprintGenerator
from collections import Counter


AMINO_ACIDS = list('ACDEFGHIKLMNPQRSTVWY')


def smiles_to_morgan_fp(smiles, radius=2, n_bits=1024):
    try:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            raise ValueError(f"Invalid SMILES: {smiles}")
        fg_gen = rdFingerprintGenerator.GetMorganGenerator(radius=radius, fpSize=n_bits)
        fp = fg_gen.GetFingerprint(mol)
        arr = np.zeros((n_bits,), dtype=int)
        AllChem.DataStructs.ConvertToNumpyArray(fp, arr)
        return arr
    except ValueError as e:
        print(f"Error processing SMILES '{smiles}': {e}")
        return None


def encode_protein_sequence(sequence):
    """
    Convert a protein sequence into a simple amino acid composition vector
    Return np.nan on failure
    """
    if not isinstance(sequence, str):
        return np.nan
    seq = sequence.strip().upper()
    if len(seq) == 0:
        return np.nan
    counts = Counter(seq)
    total = len(seq)
    composition = np.array([counts.get(aa, 0) / total for aa in AMINO_ACIDS], dtype=float)
    
    return composition


def preprocess_input(smiles, protein_sequence):
    mol_fp = smiles_to_morgan_fp(smiles)
    prot_enc = encode_protein_sequence(protein_sequence)
    
    if mol_fp is None or isinstance(prot_enc, float) and np.isnan(prot_enc).all():
        return None
    
    return np.concatenate([mol_fp, prot_enc])


# if __name__ == "__main__":
    # Example usage
    # smiles = "CCO"
    # protein_sequence = "ACDEFGHIKLMNPQRSTVWY"
    
    # mol_fp = smiles_to_morgan_fp(smiles)
    # print("Molecular Fingerprint:", mol_fp)
    
    # prot_enc = encode_protein_sequence(protein_sequence)
    # print("Protein Encoding:", prot_enc)
    
    # combined = preprocess_input(smiles, protein_sequence)
    # print("Combined Feature Vector:", combined)
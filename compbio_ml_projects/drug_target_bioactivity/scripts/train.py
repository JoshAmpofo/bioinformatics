#!/usr/bin/env python3

"""
Project title: Building a drug-target bioactivity prediction model
Project developer: Joshua Ampofo Yentumi
Script type: Training
Model: Random Forest Classifier
"""

# import libraries
import numpy as np
import pandas as pd

# ML Training libraries
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

# RDKit for chemical informatics
from rdkit import Chem
from rdkit.Chem import Descriptors, AllChem
from rdkit.Chem import rdFingerprintGenerator

# load the dataset
ki_data = pd.read_csv('data/Ki_bind.tsv', sep='\t')
ki_copy = ki_data.copy()
ki_clean = ki_copy.drop_duplicates(subset=['smiles', 'target_seq'])

# set biologically relevant affinity threshold
ki_clean = ki_clean[(ki_clean['affinity'] >= 3) & (ki_clean['affinity'] <= 12)] # keeps it in millimolar to picomolar range
ki_clean.reset_index(drop=True, inplace=True)


# aggregate by unique smile-target pairs after cleaning
ki_clean = (ki_clean.groupby(['smiles', 'target_seq'], as_index=False).
            agg({'affinity': 'mean'})
            )

# create 'activity' label based on affinity threshold (to convert project to classification task)
def classify_activity(pki):
    if pki >= 7:
        return 1 # means active
    elif pki <= 5:
        return 0 # means inactive/weak binder
    else:
        return np.nan # mark as intermediate or optional
    

# apply class labeling function
ki_clean['activity'] = ki_clean['affinity'].apply(classify_activity)
ki_clean.dropna(subset=['activity'], inplace=True)

# Encoding smiles and protein sequence columns
from tqdm import tqdm
from rdkit.DataStructs import ConvertToNumpyArray
from collections import Counter

def encode_smiles(smiles, radius=2, n_bits=1024):
    """
    convert a SMILES string to a Morgan fingerprint numpy array of length n_bits
    Returns np.nan on failure
    """
    try:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None: # if conversion fails
            return np.nan
        fp_gen = rdFingerprintGenerator.GetMorganGenerator(radius, fpSize=n_bits)
        fp = fp_gen.GetFingerprint(mol)
        # create an array sized to the fingerprint length
        arr = np.zeros((n_bits,), dtype=int)
        ConvertToNumpyArray(fp, arr)
        return arr
    except Exception as e:
        print(f"Error encoding smiles '{smiles}': {e}")
        return np.nan



AMINO_ACIDS = list('ACDEFGHIKLMNPQRSTVWY')
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


# Apply encoding functions to the dataset
tqdm.pandas()
ki_clean['smiles_fp'] = ki_clean['smiles'].progress_apply(encode_smiles)
ki_clean['protein_comp'] = ki_clean['target_seq'].progress_apply(encode_protein_sequence)

# QC
n_fail_smiles = ki_clean['smiles_fp'].isna().sum()
n_fail_protein = ki_clean['protein_comp'].isna().sum()

print(f"Number of failed SMILES encodings: {n_fail_smiles}")
print(f"Number of failed Protein sequence encodings: {n_fail_protein}")

# drop rows where either encoding failed
ki_clean = ki_clean.dropna(subset=['smiles_fp', 'protein_comp']).reset_index(drop=True)


# convert columns of arrays into feature matrices
X_mol = np.stack(ki_clean['smiles_fp'].values)
X_prot = np.stack(ki_clean['protein_comp'].values)
X = np.concatenate([X_mol, X_prot], axis=1)
y = ki_clean['activity'].values


# splitting the data
X_full_train, X_test, y_full_train, y_test = train_test_split(X, y, 
                                                              test_size=0.2, 
                                                              random_state=42)

X_train, X_val, y_train, y_val = train_test_split(X_full_train, y_full_train, 
                                                  test_size=0.25, 
                                                  random_state=42)

print(f"Train sizes: {X_train.shape}, {y_train.shape}")
print(f"Test sizes: {X_test.shape}, {y_test.shape}")
print(f"Validation sizes: {X_val.shape}, {y_val.shape}")
print(f"Original datasizes: {X.shape}, {y.shape}")

# RandomForestClassifier
rfc_f = RandomForestClassifier(n_estimators=200,
                              min_samples_split=2,
                              min_samples_leaf=1,
                              class_weight='balanced',
                              random_state=42,
                              n_jobs=-1)

rfc_f.fit(X_full_train, y_full_train)

# Save the Random Forest Classifier

import joblib # use joblib for larger models
from joblib import dump

dump(rfc_f, 'bioactivity_prediction_rf_model.joblib')
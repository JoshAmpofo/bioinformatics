from flask import Flask, render_template, request, jsonify
import requests
from rdkit import Chem
from rdkit.Chem import Descriptors, Draw, AllChem
from rdkit.Chem import rdFingerprintGenerator
import base64
from io import BytesIO
import numpy as np
from collections import Counter

app = Flask(__name__)

# GCP endpoint
BASE_MODEL_URL = 'https://dta-predictor-service-63117097702.us-central1.run.app'
PREDICT_SINGLE_URL = f"{BASE_MODEL_URL}/predict"
PREDICT_BATCH_URL = f"{BASE_MODEL_URL}/predict/batch"

# configuration
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 # 16MB limit for batch input

# preprocessing constants
AMINO_ACIDS = list('ACDEFGHIKLMNPQRSTVWY')


# ==========================================================================================
# PREPROCESSING FUNCTIONS
# ==========================================================================================

def smiles_to_morgan_fp(smiles, radius=2, n_bits=1024):
    """
    convert SMILES to Morgan fingerprint
    Returns numpy array of fingerprint bits or None on error
    """
    try:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            raise ValueError("Invalid SMILES: {smiles}")
        fp_gen = rdFingerprintGenerator.GetMorganGenerator(radius=radius, fpSize=n_bits)
        fp = fp_gen.GetFingerprint(mol)
        arr = np.zeros((n_bits,), dtype=int)
        AllChem.DataStructs.ConvertToNumpyArray(fp, arr)
        return arr
    except ValueError as e:
        print(f"Error preprocessing SMILES '{smiles}': :{e}")
        return None


def encode_protein_sequences(sequence):
    """
    convert a protein sequence into amino acid composition vector
    returns np.nan on failure
    """
    if not isinstance(sequence, str) or len(sequence) == 0:
        return np.nan
    seq = sequence.strip().upper()
    counts = Counter(seq)
    total = len(seq)
    composition = np.array([counts.get(aa, 0) / total for aa in AMINO_ACIDS], dtype=float)
    
    return composition


def preprocess_input(smiles, protein_sequence):
    """
    preprocess SMILES and protein sequence into feature vector for model input
    returns concatenated feature vector or None on error
    """
    mol_fp = smiles_to_morgan_fp(smiles)
    prot_enc = encode_protein_sequences(protein_sequence)
    
    if mol_fp is None or isinstance(prot_enc, float) and np.isnan(prot_enc).all():
        return None
    
    return np.concatenate([mol_fp, prot_enc])


# ==========================================================================================
# HELPER FUNCTIONS FOR UI
# ==========================================================================================

@app.route('/predict', methods=['POST'])
def predict_single():
    data = request.get_json()
    smiles = data.get('smiles')
    protein_sequence = data.get('protein_sequence')

    if not smiles or not protein_sequence:
        return jsonify({"error": "Both 'smiles' and 'protein_sequence' are required."}), 400

    try:
        # Preprocess input
        x = preprocess_input(smiles, protein_sequence)
        if x is None:
            raise ValueError("Preprocessing failed (invalid SMILES or sequence)")

        # Convert to numpy array
        x = np.asarray(x, dtype=float).reshape(1, -1)

        # Send request to the model hosted in Docker container
        response = requests.post(MODEL_URL, json={"input": x.tolist()})
        if response.status_code != 200:
            return jsonify({"error": "Model inference failed.", "details": response.text}), 500

        result = response.json()
        return jsonify(result)

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Unexpected error occurred.", "details": str(e)}), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    data = request.get_json()
    inputs = data.get('inputs')

    if not inputs or not isinstance(inputs, list):
        return jsonify({"error": "'inputs' must be a list of SMILES and protein sequences."}), 400

    predictions = []

    for item in inputs:
        smiles = item.get('smiles')
        protein_sequence = item.get('protein_sequence')

        if not smiles or not protein_sequence:
            predictions.append({
                "smiles": smiles,
                "protein_sequence": protein_sequence,
                "error": "Both 'smiles' and 'protein_sequence' are required."
            })
            continue

        try:
            # Preprocess input
            x = preprocess_input(smiles, protein_sequence)
            if x is None:
                raise ValueError("Preprocessing failed (invalid SMILES or sequence)")

            # Convert to numpy array
            x = np.asarray(x, dtype=float).reshape(1, -1)

            # Send request to the model hosted in Docker container
            response = requests.post(MODEL_URL, json={"input": x.tolist()})
            if response.status_code != 200:
                predictions.append({
                    "smiles": smiles,
                    "protein_sequence": protein_sequence,
                    "error": "Model inference failed.",
                    "details": response.text
                })
                continue

            result = response.json()
            predictions.append(result)

        except ValueError as e:
            predictions.append({
                "smiles": smiles,
                "protein_sequence": protein_sequence,
                "error": str(e)
            })
        except Exception as e:
            predictions.append({
                "smiles": smiles,
                "protein_sequence": protein_sequence,
                "error": "Unexpected error occurred.",
                "details": str(e)
            })

    return jsonify({"predictions": predictions})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=True)
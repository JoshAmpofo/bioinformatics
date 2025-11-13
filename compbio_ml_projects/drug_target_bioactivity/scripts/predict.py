#!/usr/bin/env python3

from preprocessing import preprocess_input
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Any
import numpy as np
import uvicorn
from joblib import load


app = FastAPI(title="Drug-Target Activity Predictor", version="1.0")

MODEL_PATH = '../models/bioactivity_prediction_rf_model.joblib'

try:
    biopred_model = load(MODEL_PATH)
except Exception as e:
    biopred_model = None
    load_error = str(e)
else:load_error = None
    

class PredictRequest(BaseModel):
    smiles: str = Field(..., example='CCO')
    protein_sequence: str = Field(..., example="MKTLLILTCLVAVALARPK")
    
    @field_validator('smiles')
    def smiles_not_empty(cls, v):
        if not isinstance(v, str) or not v.strip():
            raise ValueError("smiles must be a non-empty string")
        return v.strip()
    
    @field_validator('protein_sequence')
    def seq_not_empty(cls, v):
        if not isinstance(v, str) or not v.strip():
            raise ValueError("protein_sequence must be a non-empty string")
        return v.strip()
    

class PredictBatchRequest(BaseModel):
    inputs: List[PredictRequest]
    
    
class Prediction(BaseModel):
    smiles: str
    protein_sequence: str
    predicted_probability: float
    predicted_label: int
    message: Optional[str] = None
    

class PredictResponse(BaseModel):
    predictions: List[Prediction]


def prepare_single_input(smiles: str, sequence: str):
    """
    Preprocess a single input of smile + sequence
    Return 1D numpy array or raise valueError if preprocessing fails
    """
    try:
        vec = preprocess_input(smiles, sequence)
        if vec is None:
            raise ValueError("Preprocessing failed (invalid SMILES or sequence)")
        # convert to numpy array with numeric dtype
        arr = np.asarray(vec, dtype=float)
        
        # validate shape
        if arr.ndim != 1:
            raise ValueError(f"Preprocessed input is not 1D array, got shape: {arr.shape}")
        
        return arr
    
    except Exception as e:
        raise ValueError(f"Error in preprocessing input: {e}")
    
    except Exception as e:
        raise ValueError(f"Unexpected error in preprocessing input: {e}")


# --- Single Prediction Endpoint ---
@app.post('/predict', response_model=PredictResponse)
def predict_single(req: PredictRequest):
    if biopred_model is None:
        raise HTTPException(status_code=500, detail=f"Model not loaded: {load_error}")
    
    try:
        x = prepare_single_input(req.smiles, req.protein_sequence)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    x = x.reshape(1, -1)
    
    try:
        probs = biopred_model.predict_proba(x)[:, 1]
        
        predicted_label = int((probs >= 0.5)[0])
        label_str = "Active" if predicted_label else "Inactive"
        
        confidence = float(probs[0] * 100)
        
        prediction = Prediction(
            smiles=req.smiles,
            protein_sequence=req.protein_sequence,
            predicted_probability=float(probs[0]),
            predicted_label=predicted_label,
            message=f"The compound is predicted to be **{label_str}** with a probability of {confidence:.2f}%."
        )
        
        return PredictResponse(predictions=[prediction])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {e}")


# -- Batch prediction --
@app.post('/predict/batch', response_model=PredictResponse)
def predict_batch(req: PredictBatchRequest):
    if biopred_model is None:
        raise HTTPException(status_code=500, detail=f"Model not loaded: {load_error}")
    
    predictions = []
    
    for item in req.inputs:
        try:
            x = prepare_single_input(item.smiles, item.protein_sequence)
            x = x.reshape(1, -1)
            
            probs = biopred_model.predict_proba(x)[:, 1]
            
            predicted_label = int((probs >= 0.5)[0])
            label_str = "Active" if predicted_label else "Inactive"
            
            confidence = float(probs[0] * 100)
            
            # build prediction object
            prediction = Prediction(
                smiles=item.smiles,
                protein_sequence=item.protein_sequence,
                predicted_probability=float(probs[0]),
                predicted_label=predicted_label,
                message=f"The compound is predicted to be **{label_str}** with a probability of {confidence:.2f}%."
            )
            
            predictions.append(prediction)
        
        except ValueError as ve:
            # handle any processing error for this singular input
            prediction = Prediction(
                smiles=item.smiles,
                protein_sequence=item.protein_sequence,
                predicted_probability=0.0,
                predicted_label=-1,
                message=f"Preprocessing error: {str(ve)}"
            )
            predictions.append(prediction)
        
        except Exception as e:
            prediction = Prediction(
                smiles=item.smiles,
                protein_sequence=item.protein_sequence,
                predicted_probability=0.0,
                predicted_label=-1,
                message=f"Inference error: {str(e)}"
            )
            predictions.append(prediction)
    
    return PredictResponse(predictions=predictions)


if __name__ == "__main__":
    uvicorn.run(app, host='0.0.0.0', port=9696)


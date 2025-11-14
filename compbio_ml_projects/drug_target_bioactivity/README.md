# Drug Target Bioactivity Predictor

A production-ready machine learning system for predicting drug-target binding activity, deployed as a REST API with Docker containerization and Google Cloud Platform support.

### A mid-term project for the Machine Learning Engineering Zoomcamp by [DataTalksClub](https://github.com/DataTalksClub/machine-learning-zoomcamp/tree/master)
---

## Table of Contents
- [Problem Statement](#problem-statement)
- [Approach](#approach)
- [Data Processing](#data-processing)
- [Feature Engineering](#feature-engineering)
- [Model Results](#model-results)
- [API Usage](#api-usage)
- [Setup & Installation](#setup--installation)
- [Docker Deployment](#docker-deployment)
- [Google Cloud Deployment](#google-cloud-deployment)
- [Project Structure](#project-structure)

---

## Problem Statement

The primary goal of this project is to predict the bioactivity of a given drug-target pair. In drug discovery, it is crucial to determine whether a chemical compound (potential drug) will bind to a specific biological target (like a protein). This predictive capability allows for the efficient screening of vast chemical libraries, helping to identify promising candidates for further experimental validation. This project focuses on classifying interactions as **'Active'** or **'Inactive'** based on their binding affinity values.

---

## Approach

This problem is approached as a **supervised binary classification task**. A machine learning model is trained to learn the complex relationship between the structural features of a drug and a protein target, and their resulting bioactivity.

### Key Components

- **Features**:
    - **Drug**: Chemical descriptors generated from the drug's SMILES notation using the RDKit library. These descriptors quantify the physicochemical properties of the molecule through **Morgan fingerprints** (1024-bit vectors).
    - **Target**: The protein's amino acid sequence converted into **amino acid composition vectors** (20-dimensional frequency representation).
    
- **Models Explored**: 
    - `RandomForestClassifier` (selected for production)
    - `XGBClassifier` (backup model)
    - `LogisticRegression` (baseline model)
    
- **Evaluation Metrics**: 
    - ROC-AUC Score
    - Precision-Recall AUC
    - Classification Reports (Precision, Recall, F1-Score)
    - Confusion Matrices

---

## Data Processing

### Dataset
- **Source**: [BindingDB-for-DTA](https://www.kaggle.com/datasets/christang0002/bindingdb-for-dta) dataset from kaggle using the subset Ki binding affinity dataset (`Ki_bind.tsv`)
- **Original Size**: Multiple drug-target interaction records with binding affinity measurements (over 380,365 rows)

### Cleaning Pipeline
1. **Duplicate Removal**: Dropped exact duplicate `(smiles, target_seq)` pairs
2. **Affinity Filtering**: Restricted to biologically meaningful range: `3 ≤ affinity ≤ 12` (millimolar to picomolar)
3. **Aggregation**: Grouped by `['smiles', 'target_seq']` and averaged affinity values
4. **Label Creation**: 
   - `affinity ≥ 7` → **Active** (label = 1)
   - `affinity ≤ 5` → **Inactive** (label = 0)
   - Intermediate values (5 < affinity < 7) → Excluded from training

### Final Dataset Characteristics
- Clean, non-overlapping drug-target pairs
- Balanced class distribution considerations applied during training
- Comprehensive exploratory data analysis performed (distribution plots, correlation analysis, outlier detection)

---

## Feature Engineering

### Drug Representation: Morgan Fingerprints
```python
# Morgan fingerprint parameters
- Radius: 2
- Bits: 1024
- Generates circular substructure fingerprints
```

**Process**:
1. Parse SMILES string using RDKit
2. Generate Morgan fingerprint with radius 2
3. Convert to 1024-dimensional binary vector
4. Invalid SMILES return `None` (handled gracefully)

### Protein Representation: Amino Acid Composition
```python
# Amino acid alphabet
AMINO_ACIDS = 'ACDEFGHIKLMNPQRSTVWY'
```

**Process**:
1. Count frequency of each of the 20 canonical amino acids
2. Normalize by sequence length
3. Produces 20-dimensional composition vector
4. Invalid sequences return `np.nan` (handled gracefully)

### Combined Feature Vector
- **Total Dimensions**: 1044 (1024 molecular + 20 protein)
- **Concatenation**: `[Morgan_FP | Amino_Acid_Composition]`

---

## Model Results

### RandomForestClassifier (Production Model)

**Final Hyperparameters**:
```python
n_estimators: 200
min_samples_split: 2
min_samples_leaf: 1
class_weight: 'balanced'
random_state: 42
```

**Performance on Test Set**:
- **ROC-AUC Score**: ~0.95+ (excellent discrimination)
- **Average Precision (PR-AUC)**: High precision maintained across recall levels (~0.99)
- **Classification Metrics**: Strong precision and recall for both classes

**Key Insights**:
- Individual amino acid compositions show stronger importance than expected
- Top molecular fingerprint bits correspond to key structural motifs
- Model generalizes well with minimal overfitting

### XGBoost Classifier (Backup Model)

**Final Hyperparameters**:
```python
n_estimators: 300
max_depth: 6
learning_rate: 0.3
subsample: 1.0
colsample_bytree: 0.7
min_child_weight: 5
```

**Performance on Test Set**:
- **ROC-AUC Score**: Comparable to Random Forest (~0.94-0.96)
- **PR-AUC**: Slightly different precision-recall trade-offs (~0.98)
- **Training**: Early stopping applied to prevent overfitting

**Model Selection**: RandomForest chosen for production due to:
- Slightly better generalization
- Faster inference time
- Simpler deployment (joblib serialization)

---

## API Usage

The model is served via a **FastAPI** application with two endpoints:

### Single Prediction Endpoint

**POST** `/predict`

**Request Body**:
```json
{
  "smiles": "CCO",
  "protein_sequence": "MKTLLILTCLVAVALARPK"
}
```

**Response**:
```json
{
  "predictions": [
    {
      "smiles": "CCO",
      "protein_sequence": "MKTLLILTCLVAVALARPK",
      "predicted_probability": 0.8732,
      "predicted_label": 1,
      "message": "The compound is predicted to be **Active** with a probability of 87.32%."
    }
  ]
}
```

### Batch Prediction Endpoint

**POST** `/predict/batch`

**Request Body**:
```json
{
  "inputs": [
    {
      "smiles": "CCO",
      "protein_sequence": "MKTLLILTCLVAVALARPK"
    },
    {
      "smiles": "CC(=O)O",
      "protein_sequence": "ACDEFGHIKLMNPQRSTVWY"
    }
  ]
}
```

**Response**: Array of predictions with individual results for each input

### Error Handling
- **400 Bad Request**: Invalid SMILES or protein sequence
- **500 Internal Server Error**: Model loading or inference errors
- Graceful degradation: Batch endpoint returns error info per input without failing entire request

### Example cURL Commands

```bash
# Single prediction
curl -X POST http://localhost:9696/predict \
  -H "Content-Type: application/json" \
  -d '{
        "smiles": "CCO",
        "protein_sequence": "MKTLLILTCLVAVALARPK"
      }'

# Batch prediction
curl -X POST http://localhost:9696/predict/batch \
  -H "Content-Type: application/json" \
  -d '{
        "inputs": [
          {"smiles": "CCO", "protein_sequence": "MKTLLILTCLVAVALARPK"},
          {"smiles": "CC(=O)O", "protein_sequence": "ACDEFGHIKLMNPQRSTVWY"}
        ]
      }'
```

---

## Setup & Installation

### Prerequisites
- Python 3.11+
- Docker (for containerized deployment)
- Google Cloud SDK (for GCP deployment)

### Local Development Setup

1. **Clone the repository**:
```bash
git clone https://github.com/JoshAmpofo/bioinformatics.git
cd bioinformatics/compbio_ml_projects/drug_target_bioactivity
```

2. **Create and activate virtual environment**:
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

3. **Install dependencies** (with uv):
```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Sync dependencies
uv sync
```

**Or with pip**:
```bash
pip install -e .
```

4. **Run the API locally**:
```bash
# From project root
uvicorn scripts.predict:app --host 0.0.0.0 --port 9696

# Or using Python directly
python scripts/predict.py
```

5. **Test the API**:
```bash
curl -X POST http://localhost:9696/predict \
  -H "Content-Type: application/json" \
  -d '{"smiles": "CCO", "protein_sequence": "MKTLLILTCLVAVALARPK"}'
```

---

## Docker Deployment

### Build the Docker Image

```bash
docker build -t bioactivity-predictor .
```

### Run the Container

```bash
# Run in detached mode
docker run -d --name bioactivity-predictor -p 9696:9696 bioactivity-predictor

# View logs
docker logs -f bioactivity-predictor

# Stop container
docker stop bioactivity-predictor

# Remove container
docker rm bioactivity-predictor
```

### Docker Image Details

**Base Image**: `python:3.11-slim-trixie`
**Package Manager**: `uv` (ultra-fast Python package installer)
**Size Optimizations**: Multi-stage build with minimal base image

**Key Features**:
- Frozen dependency installation with `uv.lock`
- Optimized layer caching
- Production-ready with Uvicorn ASGI server
- Port 9696 exposed for HTTP traffic

---

## Google Cloud Deployment

### Cloud Run (Recommended)

Cloud Run provides serverless container deployment with automatic scaling.

**1. Authenticate with GCP**:
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

**2. Build and push to Artifact Registry**:
```bash
# Enable required APIs
gcloud services enable artifactregistry.googleapis.com cloudbuild.googleapis.com run.googleapis.com

# Create Artifact Registry repository (one-time setup)
gcloud artifacts repositories create bioactivity \
  --repository-format=docker \
  --location=us-central1 \
  --description="Drug bioactivity prediction models"

# Build and push image
gcloud builds submit --tag us-central1-docker.pkg.dev/YOUR_PROJECT_ID/bioactivity/bioactivity-predictor
```

**3. Deploy to Cloud Run**:
```bash
gcloud run deploy bioactivity-predictor \
  --image us-central1-docker.pkg.dev/YOUR_PROJECT_ID/bioactivity/bioactivity-predictor \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9696 \
  --memory 2Gi \
  --cpu 2 \
  --max-instances 10
```

**4. Get the service URL**:
```bash
gcloud run services describe bioactivity-predictor --region us-central1 --format='value(status.url)'
```
**OR**
Access it for this project [here](https://dta-predictor-service-63117097702.us-central1.run.app/docs)


**5. Test the deployed API**:
```bash
curl -X POST https://YOUR_SERVICE_URL/predict \
  -H "Content-Type: application/json" \
  -d '{"smiles": "CCO", "protein_sequence": "MKTLLILTCLVAVALARPK"}'
```



## Project Structure
```
drug_target_bioactivity/
├── data/                          # Training data and preprocessed features
│   ├── EC50_bind.tsv
│   ├── IC50_bind.tsv
│   ├── Kd_bind.tsv
│   ├── Ki_bind.tsv
│   ├── X_features.npy
│   └── y_labels.npy
├── models/                        # Trained model artifacts
│   ├── bioactivity_prediction_rf_model.joblib    # Production Random Forest
│   └── bioactivity_prediction_xgb_model.json     # Backup XGBoost
├── notebooks/                     # Jupyter notebooks for EDA and training
│   ├── bioactivity-pred-final.ipynb              # Final training notebook
│   ├── bioactivity_pred.ipynb
│   └── bioactivity_pred_old.ipynb
├── scripts/                       # Production code
│   ├── predict.py                 # FastAPI application
│   ├── preprocessing.py           # Feature engineering utilities
│   └── train.py                   # Tuned RF Model training script
├── Dockerfile                     # Container configuration
├── pyproject.toml                 # Python dependencies (uv format)
├── uv.lock                        # Locked dependency versions
├── .python-version                # Python version specification
├── main.py                        # Entry point (if applicable)
└── README.md                      # This file
```

---

## Key Technologies

- **Machine Learning**: scikit-learn, XGBoost
- **Cheminformatics**: RDKit
- **API Framework**: FastAPI, Pydantic
- **Server**: Uvicorn (ASGI)
- **Packaging**: uv (Python package manager)
- **Containerization**: Docker
- **Cloud Platform**: Google Cloud Platform (Cloud Run / Compute Engine)
- **Data Science**: NumPy, pandas, matplotlib, seaborn

---

## Future Enhancements

- [ ] Add support for additional binding affinity types (IC50, EC50, Kd)
- [ ] Implement model versioning and A/B testing
- [ ] Add monitoring and logging (Cloud Logging, Prometheus)
- [ ] Create interactive web UI for predictions
- [ ] Expand feature engineering (3D molecular descriptors, advanced protein embeddings)
- [ ] Implement CI/CD pipeline (GitHub Actions)
- [ ] Add comprehensive integration tests
- [ ] Support for GPU acceleration in inference

---

## License

This project is part of the bioinformatics repository by JoshAmpofo.

---

## Contact

For questions or collaboration opportunities, please reach me via email or LinkedIn.
You are also welcome to open an issue on the Github Repository.


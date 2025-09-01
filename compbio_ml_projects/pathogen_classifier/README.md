# Pathogen Classifier

ML-based viral genome classifier for Infectious diseases in Africa

## Overview

This project aims to develop a machine learning model that can classify viral pathogens from genomic sequences, with a focus on infectious diseases relevant to Africa. The classifier uses deep learning techniques to analyze viral genome sequences and predict pathogen families.

## Current Status

### ✅ Completed
- [x] **Project Setup**
  - Created project structure with proper Python packaging (`pyproject.toml`)
  - Set up virtual environment with all required dependencies
  - Configured development tools (pytest, black, flake8, mypy)

- [x] **Configuration Management**
  - Created comprehensive `config.yaml` with project settings
  - Defined data processing parameters (k-mer size, sequence lengths)
  - Set up model hyperparameters and training configurations
  - Configured logging and API settings

- [x] **Data Loading Infrastructure**
  - Implemented `Dataloader` class in `src/data_processing/data_loader.py`
  - Support for multiple file formats (FASTA, GenBank)
  - Directory-based batch processing capability
  - Integration with Biopython for sequence parsing

### 🚧 In Progress
- [ ] **Data Processing Pipeline**
  - Basic data loading functionality implemented
  - Need to add data validation and quality control
  - Metadata extraction and label generation pending

- [ ] **NCBI API Integration**
  - Biopython Entrez module ready for testing
  - API access testing and rate limit handling needed

### 📋 Planned
- [ ] **Feature Engineering**
  - K-mer extraction and encoding
  - Sequence compositional features (GC content, etc.)
  - One-hot encoding implementation

- [ ] **Model Development**
  - CNN architecture for genomic sequences
  - Training pipeline with early stopping
  - Model evaluation and validation

- [ ] **Web Interface**
  - Flask API for model predictions
  - Frontend for sequence input and classification results

## Project Structure

```
pathogen_classifier/
├── config.yaml              # Main configuration file
├── main.py                  # Entry point
├── pyproject.toml          # Python project configuration
├── requirements.txt        # Dependencies list
├── src/
│   ├── data_processing/
│   │   └── data_loader.py  # Data loading utilities
│   └── pathogen_classifier/
│       └── __init__.py
├── data/
│   ├── raw/               # Raw genomic data
│   └── processed/         # Processed features
├── models/                # Trained model storage
├── notebooks/            # Jupyter notebooks for exploration
├── tests/               # Unit tests
└── webapp/              # Flask web application
```

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd pathogen_classifier
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -e .
   # Or for development:
   pip install -e ".[dev]"
   ```

## Usage

### Basic Data Loading
```python
from src.data_processing.data_loader import Dataloader
import yaml

# Load configuration
with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)

# Initialize data loader
loader = Dataloader(config)

# Load genomic sequences
sequences = loader.load_data()
print(f"Loaded {len(sequences)} sequences")
```

## Configuration

The project uses a centralized configuration system via `config.yaml`. Key settings include:

- **Data paths**: Location of raw and processed data
- **Sequence parameters**: K-mer size, length filters
- **Model settings**: Architecture, hyperparameters
- **Training configuration**: Batch size, learning rate, epochs
- **Logging**: Output levels and file locations

## Target Pathogen Families

Currently configured to classify:
- Coronaviridae (COVID-19, SARS, MERS)
- Orthomxyoviridae (Influenza viruses)
- Flaviviridae (Dengue, Zika, Yellow Fever)
- Filoviridae (Ebola, Marburg)
- Paramyxoviridae (Measles, Mumps)

## Dependencies

### Core ML Stack
- numpy, pandas, scikit-learn
- tensorflow, keras
- matplotlib, seaborn

### Bioinformatics
- biopython
- scikit-bio

### Web Framework
- flask, flask-cors
- gunicorn

### Development Tools
- pytest, black, flake8
- mypy, pre-commit

## Contributing

This project is under active development. Current focus areas:
1. Data pipeline completion and testing
2. NCBI API integration and testing
3. Feature engineering implementation
4. Model architecture development

## License

MIT License - see LICENSE file for details.

## Author

Joshua Ampofo Yentumi (ampofojoshuayent@gmail.com)

---

*Last updated: September 1, 2025*
# Session Briefing Source Pack

Project: pathogen_classifier
Session date: 2026-06-24
Session id: unknown
Generated: 2026-06-24T12:53:34Z
Goal: yes, let's just update the README with a short description

## What changed

- Files created: 9
- Files edited: 4
- Files deleted: 0
- Commands run: 15
- Failed commands: 0

## Why it matters

This pack is generated from the vibe-learn session log. Use it to understand
what the agent changed, which files deserve inspection, and what you should be
ready to debug or extend.

## Timeline

- Command: cd /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier && echo "=== tree ===" && find . -type f -not -path './.git/*' -not -path './.venv/*' | head -50 && echo "" && echo "=== src layou (exit 0)
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio 2>/dev/null && python -c "
import sys; print('python', sys.version.split()[0])
for m in ['sklearn','numpy','pandas','Bio (exit 0)
- Command: echo "=== root config.yaml exists? diff with config/config.yaml ===" && diff config.yaml config/config.yaml && echo "IDENTICAL" || echo "(differ or one missing)"
echo ""
echo "=== __init__ files prese (exit 0)
- Command: mkdir -p src/features src/models src/evaluation data/raw data/processed results tests && touch src/__init__.py src/data_processing/__init__.py src/features/__init__.py src/models/__init__.py src/evalu (exit 0)
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/config.py
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/download.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 240 python -m src.data_processing.download --per-family 3 2>&1 | tail -40 (exit 0)
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "
import pandas as pd
df = pd.read_csv('data/metadata.csv')
print(df[['family','length']].groupby('family') (exit 0)
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m src.data_processing.download --per-family 300 > /tmp/openvirotax_download.log 2>&1 (exit 0)
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/fragment.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "
import pandas as pd
df = pd.read_csv('data/metadata.csv')
print('TOTAL genomes:', len(df))
print()
g = df (exit 0)
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/tests/test_fragment.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_fragment.py -q 2>&1 | tail -15 (exit 0)
- Prompt: let's keep the sample_fragments() with a length-weighted random strategy
- File edited: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/fragment.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_fragment.py -q 2>&1 | tail -8 (exit 0)
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "
import random, pandas as pd
from pathlib import Path
from Bio import SeqIO
from src.config import load_co (exit 0)
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/build_fragments.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "import pyarrow" 2>/dev/null && echo "pyarrow OK" || pip install pyarrow -q 2>&1 | tail -2
python -m src.da (exit 0)
- File created: /home/reyes/bioinformatics/.remember/remember.md
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/features/kmers.py
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/tests/test_kmers.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_kmers.py -q 2>&1 | tail -6 && echo "=== build features ===" && time python -m src.feature (exit 0)
- File created: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/models/classifier.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 180 python -m src.models.classifier 2>&1 | tail -8 (exit 0)
- Prompt: let's pick option C, works as the best of both worlds. If we have enough data, we use isotonic, else if we have a rare class, we switch to sigmoid
- File edited: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/models/classifier.py
- Command: source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 400 python -c "
import numpy as np, pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from  (exit 0)
- File edited: /home/reyes/bioinformatics/.remember/remember.md
- Prompt: great, let's pause here
- Prompt: I'll do the commit myself. Is there a README documenting the project?
- Prompt: yes, let's just update the README with a short description
- File edited: /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/README.md

## Important files

### Created
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/config.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/build_fragments.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/download.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/fragment.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/features/kmers.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/models/classifier.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/tests/test_fragment.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/tests/test_kmers.py
/home/reyes/bioinformatics/.remember/remember.md

### Edited
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/README.md
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/data_processing/fragment.py
/home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier/src/models/classifier.py
/home/reyes/bioinformatics/.remember/remember.md

### Deleted


## Commands and failures

- cd /home/reyes/bioinformatics/compbio_ml_projects/pathogen_classifier && echo "=== tree ===" && find . -type f -not -path './.git/*' -not -path './.venv/*' | head -50 && echo "" && echo "=== src layou (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio 2>/dev/null && python -c "\nimport sys; print('python', sys.version.split()[0])\nfor m in ['sklearn','numpy','pandas','Bio (exit 0)
- echo "=== root config.yaml exists? diff with config/config.yaml ===" && diff config.yaml config/config.yaml && echo "IDENTICAL" || echo "(differ or one missing)"\necho ""\necho "=== __init__ files prese (exit 0)
- mkdir -p src/features src/models src/evaluation data/raw data/processed results tests && touch src/__init__.py src/data_processing/__init__.py src/features/__init__.py src/models/__init__.py src/evalu (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 240 python -m src.data_processing.download --per-family 3 2>&1 | tail -40 (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "\nimport pandas as pd\ndf = pd.read_csv('data/metadata.csv')\nprint(df[['family','length']].groupby('family') (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m src.data_processing.download --per-family 300 > /tmp/openvirotax_download.log 2>&1 (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "\nimport pandas as pd\ndf = pd.read_csv('data/metadata.csv')\nprint('TOTAL genomes:', len(df))\nprint()\ng = df (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_fragment.py -q 2>&1 | tail -15 (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_fragment.py -q 2>&1 | tail -8 (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "\nimport random, pandas as pd\nfrom pathlib import Path\nfrom Bio import SeqIO\nfrom src.config import load_co (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -c "import pyarrow" 2>/dev/null && echo "pyarrow OK" || pip install pyarrow -q 2>&1 | tail -2\npython -m src.da (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && python -m pytest tests/test_kmers.py -q 2>&1 | tail -6 && echo "=== build features ===" && time python -m src.feature (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 180 python -m src.models.classifier 2>&1 | tail -8 (exit 0)
- source /home/reyes/miniconda3/etc/profile.d/conda.sh && conda activate comp-bio && timeout 400 python -c "\nimport numpy as np, pandas as pd\nfrom sklearn.calibration import CalibratedClassifierCV\nfrom  (exit 0)

## Key code excerpts

```diff
diff --git a/compbio_ml_projects/pathogen_classifier/README.md b/compbio_ml_projects/pathogen_classifier/README.md
index dcdbd07..5bbe054 100644
--- a/compbio_ml_projects/pathogen_classifier/README.md
+++ b/compbio_ml_projects/pathogen_classifier/README.md
@@ -2,6 +2,24 @@
 
 ML-based viral genome classifier for Infectious diseases in Africa
 
+> ⚠️ **Under active rework — OpenViroTax-Africa (June 2026).** This project is
+> being rebuilt as **OpenViroTax**: a *confidence-calibrated, abstaining,
+> fragment-aware* viral-family classifier. We pivoted from the original
+> TensorFlow/CNN plan to a **scikit-learn** pipeline so the focus can be on the
+> research contribution — knowing *when not to trust* a prediction — rather than
+> heavy model training.
+>
+> **Pipeline:** NCBI RefSeq genomes (7 families) → length-weighted fragmentation
+> (250/500/1000 bp contigs) → k-mer + GC features → calibrated classifier →
+> conformal abstention → leave-one-family-out novelty detection.
+>
+> **Progress so far:** 730 genomes downloaded; 46k fragments; k-mer features;
+> calibrated Random Forest (Expected Calibration Error improved ~3×, 0.23 → 0.075).
+> Abstention, novelty detection, and the benchmark are in progress.
+>
+> Full plan: [`.claude/plans/woolly-imagining-swan.md`](../../../.claude/plans/woolly-imagining-swan.md).
+> The sections below describe the **original** project plan and are partly stale.
+
 ## Overview
 
 This project aims to develop a machine learning model that can classify viral pathogens from genomic sequences, with a focus on infectious diseases relevant to Africa. The classifier uses deep learning techniques to analyze viral genome sequences and predict pathogen families.
```

## Review questions

- What changed in the main execution path?
- Which touched files would I inspect first if the app broke?
- Were tests or build checks run after the changes?
- Did any command fail, and what follow-up does that imply?

## Suggested audio framing

Create a maintainer-focused audio overview. Explain what changed, why it
matters, what to inspect first, and what could break. Assume the listener owns
this codebase and needs enough technical depth to support it.

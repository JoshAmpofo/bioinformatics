## Drug Target Bioactivity Predictor

### Problem Statement
The primary goal of this project is to predict the bioactivity of a given drug-target pair. In drug discovery, it is crucial to determine whether a chemical compound (potential drug) will bind to a specific biological target (like a protein). This predictive capability allows for the efficient screening of vast chemical libraries, helping to identify promising candidates for further experimental validation. This project focuses on classifying interactions as 'active' or 'inactive' based on their binding affinity values.

### The Machine Learning fit
This problem is approached as a supervised binary classification task. A machine learning model will be trained to learn the complex relationship between the structural features of a drug and a protein target, and their resulting bioactivity.

- **Features**:
    - **Drug**: Chemical descriptors will be generated from the drug's SMILES notation using the RDKit library. These descriptors quantify the physicochemical properties of the molecule.
    - **Target**: The protein's amino acid sequence will be converted into numerical representations that the model can process.
- **Model**: The project will explore ensemble models like `RandomForestClassifier` and `XGBClassifier` to handle the complexity of the feature space and make accurate predictions.
- **Evaluation**: The model's performance will be assessed using metrics such as AUC-ROC, classification reports, and confusion matrices to ensure its predictive power and reliability.


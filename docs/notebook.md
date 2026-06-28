# Lab Notebook: KG Construction

## 2026-06-26
### Objective
* **Goal:** Survey the distribution of relation types in the training data. Both before harmonization, for each dataset. And after harmonization.
* **Expectation:** The distribution of relations in the training data is similar to the distribution of relations extracted by the Pubtator 3 tool in practice. In both, the predominant relation type is "associate".

### What I did
* Set up the virtual environment for this project folder
```bash
# Navigate to the project directory
cd D:\Users\Jessica\kg-construction

# Creates the environment inside the project folder under a hidden folder named .conda_env
conda create -p ./.conda_env python=3.11 -c conda-forge -y

# Activate the virtual environment
conda activate ./.conda_env

# Install necessary packages, make sure the virtual environment is activated
pip install jupyter ipykernel requests pandas
```
* Download the datasets used to train BioREx
```bash
# 1. Create the specific subfolder for the dataset
mkdir -p data/00_raw/biorex

# 2. Download the zip file directly into that folder using curl
curl -L https://ftp.ncbi.nlm.nih.gov/pub/lu/BioREx/datasets.zip -o data/00_raw/biorex/datasets.zip

# 3. Unzip the files directly inside that directory
unzip data/00_raw/biorex/datasets.zip -d data/00_raw/biorex/

# 4. Remove the temporary zip file to save space
rm data/00_raw/biorex/datasets.zip
```
* See `01_pubtator_metrics.ipynb`
    * "Overview of Relation Type Counts in BioREx Training Data"

* Fetch the full relations file from Pubtator
```bash
cd /d/Users/Jessica/kg-construction

mkdir -p data/00_raw/pubtator

curl -L https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/relation2pubtator3.gz -o data/00_raw/pubtator/relation2pubtator3.gz

curl -L https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/bioconcepts2pubtator3.gz -o data/00_raw/pubtator/bioconcepts2pubtator3.gz
```

### Conclusions/Next Steps
* The BioREx model is really only capable of predicting 3 different relations: Association, Negative Correlation, and Positive Correlation
    * The examples for the other relation types are insufficient
    * Pubtator relations must be mapped to BioREx
    * The "conversion" relation from BioREx is not found in the Pubtator relations
* The reason for so many missing relations was likely because the training dataset contained 76% entity pairs with the relation "none". Not directly testable as the none relation types were not included in the pubtator relations. Could only be inferred by the number of papers with 0 relations extracted
* Why did the extraction fail for so many abstracts? Is it because they did not have any of the entity type pairs that the model was looking for? Eight entity type pairs: chemical–chemical, chemical–disease, chemical–gene, chemical–variant, disease–gene, disease–variant, gene–gene and variant–variant
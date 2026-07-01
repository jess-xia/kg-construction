# Lab Notebook: KG Construction

## 2026-06-26
### Objective
Survey the distribution of relation types in the training data. Both before harmonization, for each dataset. And after harmonization.

### Expectation
The distribution of relations in the training data is similar to the distribution of relations extracted by the Pubtator 3 tool in practice. In both, the predominant relation type is "associate".

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
    * Note: ncbi_relation is where the BioRED annotations are stored. According to: https://github.com/ncbi/BioREx/blob/main/scripts/build_biorex_datasets.sh
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
    * "BioREx Training Data Relation Type Counts"
    * "Pubtator 3 Relation Type Counts"
    * "Mapping Pubtator to BioREx Relations"

* Fetch the full relations file from Pubtator
```bash
cd /d/Users/Jessica/kg-construction

mkdir -p data/00_raw/pubtator

curl -L https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/relation2pubtator3.gz -o data/00_raw/pubtator/relation2pubtator3.gz

curl -L https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/bioconcepts2pubtator3.gz -o data/00_raw/pubtator/bioconcepts2pubtator3.gz
```

* Create new github repository
```bash
# 1. Initialize this folder as a Git repository
git init

# 2. Add all your files to the staging area
git add .

# 3. Commit the files with an initial message
git commit -m "Initial commit: BioREx training vs Pubtator performance"

# 4. Rename your default branch to 'main' (GitHub's standard branch name)
git branch -M main

# 5. Link your local project to your GitHub repository 
# (Paste the URL you copied in Step 1 here)
git remote add origin https://github.com/jess-xia/kg-construction.git

# 6. Push your files up to GitHub!
git push -u origin main
```

### Conclusions/Next Steps
* The BioREx model is really only capable of predicting 3 different relations: Association, Negative Correlation, and Positive Correlation
    * The examples for the other relation types are insufficient
    * Pubtator relations must be mapped to BioREx
    * The "conversion" relation from BioREx is not found in the Pubtator relations
* The reason for so many missing relations was likely because the training dataset contained 76% entity pairs with the relation "none". Not directly testable as the none relation types were not included in the pubtator relations. Could only be inferred by the number of papers with 0 relations extracted
* Why did the extraction fail for so many abstracts? Is it because they did not have any of the entity type pairs that the model was looking for? Eight entity type pairs: chemical–chemical, chemical–disease, chemical–gene, chemical–variant, disease–gene, disease–variant, gene–gene and variant–variant


## 2026-06-29
### Objective
Understand how NER and RE works in Pubtator 3. What pretrained model did they use and what fine-tuning was done? How does Pubtator compare to other tool architectures?

### Readings
* BioREx workflow 
    * BioREx requires entity spans - Uses entity spans present in text when available. If not, Pubtator annotated entity spans are used.
    * BioREx generates all possible entity pairs and for each pair creates an instance of the text, the two entities and boundary tags altogether wrapped in a prompt.
* iKraph is trained using BioRED data as well, this is described on their Github (https://github.com/myinsilicom/iKraph/tree/main)
    *  Their team, JZhangLab@FSU, participated in the challenge NIH organized the LitCoin natural language processing (NLP) challenge between Nov 2021 and Feb 2022 and won first place
    *  In the summer of 2023, we also participated in the BioRED track of the BioCreative Challenge VIII. In the end-to-end KG construction task, our team also achieved the highest score (https://doi.org/10.1101/2023.10.13.562216) --> Table 1 shows that iKraph is team 156. But strangely there is no mention of iKraph from this paper (https://academic.oup.com/database/article/doi/10.1093/database/baae069/7729400#484143431) where they only mention that BioREx is the top performer
    * I understand now (https://zenodo.org/records/10351131): BioREx was used as a baseline result. On the BioCreative task competition, iKraph was the top performer. Even outperforming BioREx 
* Few-Shot Biomedical Relation Extraction with Large Language Models: A Viable Alternative to Supervised Learning? Mraz 2026 (https://arxiv.org/pdf/2606.15412)
    * This paper clearly describes some of what I found in BioRED: Imbalanced relation type distribution with Association, Positive Correlation, and Negative Correlation accounting for more than 95% of all relation instances and ambiguity of the association class
    * Compared between two methods of prompting: Pairwise classification and joint generation. Joint generation reduces computational costs by 25x
    * The authors also use BioREDirect, the directional version of BioRED
* GLiNER-Relex: A Unified Framework for Joint Named Entity Recognition and Relation Extraction 2026 May (https://arxiv.org/html/2605.10108)
    * Joint NER & RE model outside of the biomedical domain. 
    * Does not use a fixed ontology. Treats entity-type names and relation-type names as natural-language tokens in the input and embeds them all together in one sequence. 
    * Identifies entities by finding the tokens with embeddings most similar to the entity-type names. 
    * Then it takes the embedding of the entity pair, and compares with with the embedding of the relation label to find the relation label most similar
* The overview of the BioRED (Biomedical Relation Extraction Dataset) track at BioCreative VIII, 2024 August (https://doi.org/10.1093/database/baae069)
    * GPT-3.5 and GPT-4 are given the list of manually annotated entities and the abstract text. They are then prompted to identify the relation type between a pair of relations. 
    * Overall, both perform very poorly on the BioRED track (Table 2). 
        * When looking at the entity pair predictions, precision is very low but recall is very high --> Low precision suggests that GPT is predicting lots of entity pairs that are not present in the BioRED annotations. These could be mistakes on GPT's part but it could also be due to missing annotations in the BioRED dataset. High recall suggests that GPT is not clueless, it clearly has some decent understanding of the english language. If both precision and recall were low, that would better support the argument that GPT is just bad at the job.
        * When looking at the entity pair + relation type predictions, both precision and recall are low --> this suggests that even for the entity pairs it correctly identified, it failed to pick the right relation type. Again, is the manual annotation right or is GPT? 
        * To look into this closer, I must get the GPT annotations. This is not provided by the authors, but they do provide the prompt. It should not be too difficult to replicate
    * This paper was later cited by: Enhancing biomedical relation extraction with directionality, 2025 July (https://doi.org/10.1093/bioinformatics/btaf226)
        * The authors performed instructional fine-tuning of the LLM (Figure 3) which resulted in a huge jump in performance (Table 2)
        * This seems suspicious to me as it is less instruction fine tuning and more structured output. I do not expect this alone to result in such a large jump in performance. It is nearly comparable to BioREx. This suggests that the concerns from the 2024 August paper are not major, but could be dramatically improved rather simply. But based on my hypotheses on why the BioRED dataset may be of concern, I do not think simple instructional fine tuning is sufficient.
* LLMs have been used for data augmentation (https://zenodo.org/records/10117973)
    * Typically involving paraphasing input text to create similar sentences in the same context

### Objective
Evaluate the annotation quality of BioRED. Look at the distribution of the relation types in the BioRED set. 

### Expectation
The distribution of the relation types in the BioRED set is similar to that in the BioREx training set. This is already described by Mraz 2026. The difference that the authors of that paper performed the evaluation of the test split of BioREDirect. Which is also directional.

### What I did
* See `01_pubtator_metrics.ipynb`
    * "BioRED Relation Type Distribution"
* Computed summary statistics for BioRED in terms of the number of unique entities and relations extracted
* Plotted the distribution of relation types

### Conclusions/Next Steps
* Only 7 of the 600 abstracts (1.17%) across the dev, test, and train datasets had 0 relations extracted. This disproportionate number of abstracts with no relations after Pubtator extraction is not seen in the BioRED dataset.
    * Across the whole BioREx training set, the percentage of papers with 0 relations extracted is 26.88%
    * This is further evidence that the issue is in the number of "None" labels
* The distribution of relation type counts in BioRED is similar to the BioREx training set and the Pubtator distribution. 
* Idea: Look at interannotator consensus when it comes to annotating relation types with different LLMs. Take average? Use each set of annotations for training?
* iKraph seems to be trained on BioRED without all the none annotations. It has also been run on the entirety of Pubmed. The next logical step may be to look at all the iKraph annotations and look at the distribution of relation types. I expect much fewer papers with 0 relations extracted. 


## 2026-06-30
### Objective
Download and analyze iKraph data, survey the distribution of relation types

### Expectation
There are much fewer "none" values in the iKraph dataset compared to Pubtator 3. Majority of relations remains to be "associate"

### What I did
```bash
# Download the full iKraph data file
curl -o data/00_raw/ikraph/iKraph_full.tar.gz https://zenodo.org/records/14851275/files/iKraph_full.tar.gz

# Navigate to the directory of the iKraph file and extract from compressed file
tar -xvf iKraph_full.tar.gz

# Delete the original compressed file
rm iKraph_full.tar.gz
```
* See `01_pubtator_metrics.ipynb`
    * "iKraph Relation Type Distribution"

### Findings
* Similar to what I found with Pubtator, nearly 70% of all papers had 0 extractions.
* The reason this is the case is likely that when training they took all the entity pairs in the abstract and assigned them the relation none when there was no relation explicitly specified for the pair. Would need to look into how they did the training
    * In BioRED the median number of entities per paper is 10 and the median number of relations per paper is 8 - based on my analysis here `BioRED Relation Type Distribution`
    * From 10 entities, the number of unique entity pairs is 10 choose 2 = 45
    * The median number of "none" relations is 45-8 = 37. 
    * The median percentage of "none" relations is 37/45 = 82%
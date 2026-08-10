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
    * It is not the extension of the BioRED dataset in BioREx that is the issue.
    * BioRED is the issue
* The reason this is the case is likely that when training they took all the entity pairs in the abstract and assigned them the relation none when there was no relation explicitly specified for the pair. Would need to look into how they did the training
    * In BioRED the median number of entities per paper is 10 and the median number of relations per paper is 8 - based on my analysis here `BioRED Relation Type Distribution`
    * From 10 entities, the number of unique entity pairs is 10 choose 2 = 45
    * The median number of "none" relations is 45-8 = 37. 
    * The median percentage of "none" relations is 37/45 = 82%
* "None" is the hidden label being used in training, and it seems to be overpowering the other labels.
* Next step: Manually look at the BioRED annotations. 
    * Are the annotations accurate? Are they comprehensive? Are they as granular as they can be?


## 2026-07-03
### Objective
Manually go through some BioRED annotations and assess their informativeness and accuracy. 

### Case Studies
Going sequentially down the list of PMIDs in Train.PubTator
#### 10491763
* Annotations
    * HNF-6 Association Type II diabetes mellitus
    * glucose Positive_Correlation insulin
    * glucose Association Type II diabetes mellitus
* Main findings of the paper
    * HNF-6 mutations not associated with Type II diabetes 
    * HNF-6 mutations not associated with changes in insulin responses to glucose
* Notes:
    * This abstract contains stats and methods descriptions. Triples cannot be easily extracted except from the conclusion.
    * In a way, HNF-6 Association Type II diabetes mellitus almost contradicts what the paper finds. The finding is that there is no association but "not associated" is not a relation type in the list
    * It is unclear how glucose Positive_Correlation insulin is extracted
#### 10661407
* Annotations
    * Langerin Bind mannose
* Notes:
    * The only two entities identitied by Pubtator 3 in this abstract are Langerin and mannose. This extraction accurately captures their relationship
    * Another possible extraction would be "Langerin associated with BG" but Birbeck granules are not extracted. Birbeck granules maps to "Langerhans' granule" in UMLS
#### 10788334
* Annotations
    * breast cancer, ovarian cancer, breast-ovarian cancer, BRCA1 Positive_Correlation 5382insC, 4153delA, C61G
    * BRCA1 Association breast cancer, ovarian cancer, breast-ovarian cancer, BRCA1 abnormalities
* Notes:
    * Again, this paper is rather epidemiological with lots of numbers and methods descriptions. 
    * For the most part i would say these triples extracted are accurate
#### 11009181
* Annotations
    * levodopa Positive_Correlation dyskinesias
    * apomorphine Negative_Correlation levodopa, dyskinesias, Parkinson's disease
* Notes:
    * I would say these are mostly accurate

### Findings
* The annotations are generally accurate, nothing too concerning. 
* Question: How were the papers selected in the BioRED dataset? Are they clinical papers?
    * Randomly sampled articles from several existing datasets (i.e. NCBI Disease, NLM-Gene, GNormPlus, BC5CDR and tmVar)
    * Look into the MeSH terms of these papers. Look into the types of papers these are. Primary research? Review?

### Objective
Look into the types of papers included in the BioRED corpus.

### Findings
* See `BioRED Relation Type Distribution` in `01_pubtator_metrics.ipynb`
* Approximately 15-20% of papers are clinical
* Almost all papers are primary papers rather than review articles --> this is good for KG construction.
* There are many medical genetics/genomics papers. Terms like Mutation (15.83%), Genotype (15.33%), Polymorphism, Single Nucleotide (14.33%), and Genetic Predisposition to Disease (9.67%) dominate the non-demographic tags

## 2026-07-06
### Brainstorming
* I do not want to develop a new architecture/framework
* Rather, show that LLM derived synthetic training data can be used to improve the performance of existing frameworks for relation extraction
* Triple extraction consists of two parts: NER and RE
* NER and normalization is a nontrivial task, yet not a particularly challenging task
    * Current tools e.g. Pubtator 3 can do a decent job at it, with reasonable coverage of 6 entity types (genes/proteins, chemicals, diseases, species, genetic variants, and cell lines)
    * What can be improved on is phenotypic entities e.g. "angiogenesis", "invasion", but that would require large amounts of training data
    * NER requires many steps but in itself is not a challenging problem as it is primarily a string matching task that does not require much logic
    * If a RE pipeline works well for a given set of entities, it likely can work well for other entities as well
* What may be interesting and publishable is if LLMs can be used to generate synthetic data for training smaller transformer e.g. BERT models and result in better accuracy and coverage than training on manual annotations alone for relation extraction
    * I could compare between the different LLMs e.g. chatgpt, gemini, claude 
    * I could determine the rate of improvement with increasing size of annotated training corpus
    * My evaluation could be against PubMedQA. What else?
* To read:
    * Tuning for clinical concept and relation extraction: https://github.com/jkbmrz/few-shot-biore.
* Tentative Approach
    * Use the same pretrained model and transformer architecture as BioREx. Can start with just the BioRED dataset, use this one which is larger and contains 1000 abstracts (https://academic-oup-com.myaccess.library.utoronto.ca/database/article/doi/10.1093/database/baae069/7729400)
    * My hypothesis is that LLM annotated triples are similarly if not more effective than human annotations for training a transformer for relation extraction
        * First, I must see how LLM extracted triples compare directly to BioRED annotations. Garbage in garbage out. I must have some degree confidence regarding the quality of these triples compared directly. From this paper https://academic-oup-com.myaccess.library.utoronto.ca/database/article/doi/10.1093/database/baae069/7729400 it seems that GPT 3.5 and GPT 4 have high recall for recognizing entity pairs. Though the perform very poorly on all other measures.
        * Fine tuning of these LLMs drastically boosted performance to being almost comparable to BioREx. https://academic-oup-com.myaccess.library.utoronto.ca/bioinformatics/article/41/Supplement_1/i68/8199369#525745429
    * Ignore directionality for now. Directionality is not very important for the BioRED schema. 
    * The BioRED schema is ok. The problem is Pubtator does not perform nearly as well as it is advertised to.
    * LLMs have been used for dataset augmentation. Generating paraphrases and different wordings of the same relations
        * https://arxiv.org/pdf/2405.20787
        * https://www-sciencedirect-com.myaccess.library.utoronto.ca/science/article/pii/S0010482525006365#bib43
    * Analyses to do:
        1. Directly feed in abstracts to Gemini and prompt it to extract relations following the BioRED schema given entities extracted by Pubtator 3
            * Evaluate precision, recall for entity pairs (regardless of order and relation type) and for entity pairs + relation type
            * Look at the distribution of relation type frequencies
        2. Use BioRED annotations and LLM annotations to separately train two BERT models for relation extraction
            * Match training set sizes then vary them. See if an increase in LLM annotated abstracts can improve performance
            * Aggregate performance across all classes but also look at each relation type separately
            * Also look at entity pairs without the relation type. If the model can more accurately predict entity pairs that is an improvement as well
            * Compare their performance when used as context for PubMedQA
            * Can compare across different LLMs
            * Can compare LLM-based augmentation vs LLM synthetic data generation. 

### Objective
Assess the quality of LLM-extracted relations using the BioRED dataset. If they are comparable to the manual annotations, that is a good sign meaning they are likely suitable to be used to fine tune the pretrained model. If they are drastically different, I will likely need to rethink the comparison. Refer to prompts from these papers: https://arxiv.org/pdf/2606.15412 (https://github.com/jkbmrz/few-shot-biore/blob/main/utils/prompt/make.py), https://academic-oup-com.myaccess.library.utoronto.ca/database/article/doi/10.1093/database/baae069/7729400, https://academic-oup-com.myaccess.library.utoronto.ca/bioinformatics/article/41/Supplement_1/i68/8199369#525745429. Look at primarily the first paper. 
* Note:
    * https://github.com/jkbmrz/few-shot-biore/blob/main/utils/prompt/make.py this source did not describe each relation type but assumed that the LLM understood

### What I did
* See `02_LLM_RE.ipynb`
* Downloaded the 1000 abstract dataset from BioRED.
```bash
# Create directory
mkdir -p data/00_raw/BioRED

# Navigate to it
cd data/00_raw/BioRED

# Download only Subtask 1 files
curl -O https://ftp.ncbi.nlm.nih.gov/pub/lu/BC8-BioRED-track/BC8_BioRED_Subtask1_BioCJSON.zip
curl -O https://ftp.ncbi.nlm.nih.gov/pub/lu/BC8-BioRED-track/BC8_BioRED_Subtask1_BioCXML.zip
curl -O https://ftp.ncbi.nlm.nih.gov/pub/lu/BC8-BioRED-track/BC8_BioRED_Subtask1_PubTator.zip
curl -O https://ftp.ncbi.nlm.nih.gov/pub/lu/BC8-BioRED-track/BC8_BioRED_Subtask1_Test_Set.zip

# Extract zip files
unzip "*.zip"

# Extract tar files
tar -xvf biored_re_model.tar
tar -xvf biored_re_source_code.tar

pip install bioc
```
* `result_biored_relation_batch_0707_1020.jsonl` is the result of the initial prompt where I do not emphasize the requirement to choose from the 7 relation types. Gemini 2.5 Flash used.
* `result_biored_relation_batch_0707_1311.jsonl` is the result where I included the requirement to choose from the 7 relation types. Did not seem to help much, there are still many entity pairs that I don't want being extracted. I address this by filtering them out. Gemini 2.5 Flash used.
* `result_biored_relation_batch_0707_1501.jsonl`. Same prompt as `result_biored_relation_batch_0707_1311.jsonl` but Gemini 2.5 pro is used.
* `result_biored_relation_batch_0708_1030.jsonl`. Same prompt as previous. Ran all 600 abstracts of BioRED through Gemini 2.5 Flash

### What I found
* I performed triple extraction on a set of 10 abstracts following the BioRED annotation guidelines as best I could comparing between Gemini 2.5 Flash and Gemini 2.5 Pro
    * Pro used slightly fewer output tokens (60k vs 68k)
    * But cost 3x more (0.03USD vs 0.01 per abstract)
    * F1 score for entity pair match was identical
    * F1 score for entity pair + relation type match was very slightly higher (0.46 vs 0.42)
    * Relation type distribution was near identical between the two models. Comparing between Gemini and the manual annotations, there are fewer "association" relations and more "positive_correlation" and "negative_correlation" 
    * One difference between the two models is that Gemini 2.5 Pro may be better at following instructions
        * Raw triples extracted by Flash and Pro were 77 and 66 respectively
        * After filtering for only the 7 relation entity type pairs we were interested in, there were 57 and 59 remaining
        * More relations from Gemini 2.5 flash had to be filtered out
        * But after filtering, the performance is rather similar. 
* Given the cost-benefit comparison, I will stick to Gemini 2.5 Flash for now
* After running all 600 abstracts through Gemini 2.5 Flash, I saw a similar trend as when I ran just the 10 abstract trial
    * Gemini predicted fewer "association" and more "positive correlation" and negative correlation"
    * The individual relation type metrics are comparable to the publication https://arxiv.org/pdf/2606.15412 (Table 3), in my results I find that cotreatment also has the highest F1 score followed by negative and positive correlation
    * The difference between Gemini extractions and manual annotations is a combination of a shifted distribution of relation types from heavy on association to higher in positive and negative correlation as well as a mismatch is relation types predicted. 
* What's reassuring is that the gemini extractions are not drastically different from the manual annotations.
    * Still, most relations are association, positive correlation, and negative correlation
    * Still, association type outnumbers positive correlation and negative correlation
    * While the F1 scores for entity pair + relation type prediction is low (Micro F1 = 0.50, Macro F1 = 0.47), the F1 score for entity pair alone is much higher, 0.7

## 2026-07-08
### Ideas
* Potential modifications to model architecture:   
    * BioREx uses a marker-based pairwise encoding approach. Alternatively, I can try a shared encoding with span pooling approach whereby I take the embedding vectors of the two entities of interest, concatenate it with some context. Rather than feeding the entire sentence repeatedly into the model with the spans labelled
    * BioREx performs extraction all in one go whereby the "none" label is included as one of the relation types. Alternatively, I can split relation extraction into two stages. First, classify whether or not a relation exists. And second, classify the specific relation.
* The above modifications could potentially be good extensions. But they are not directly relevant to the question I am interested in.
* First, I will replicate BioREx's architecture, changing only the training data.

### Objective
Figure out how BioREx/iKraph performed the training and learn how to do this on compute canada.

## 2026-07-13
### Objective
Set up compute canada for fine tuning pretrained model. Start by replicating what was done with BioREx with the full harmonized dataset, then replicate BioREx pipeline using only the BioRED dataset. Finally, run BioREx pipeline on Gemini Triples.

### What I did
* Using the special allocation on Fir (rrg-hroest), runs GPU jobs very quickly
    * Nibi showed no storage available. 
    * Narval has 24T available. Tried using Narval but I had to wait for a really long time for my GPU job to run. 
* Made a folder named biorex_replication
* Create the project folder, clone the BioREx repository, download the datasets and pretrained model
    * Note: The model was initially called PubmedBERT but as been changed to BiomedBERT. I addressed this by creating a symbolic link
```bash
# Create and navigate to project folder
mkdir biorex_replication
cd biorex_replication
# Clone the official BioREx repository code into your workspace
git clone https://github.com/ncbi/BioREx.git


# Create a dedicated directory for your training and evaluation data
mkdir datasets
cd /home/jexia/biorex_replication/BioREx/datasets
# Download the pre-converted biomedical relation extraction datasets from NCBI
wget https://ftp.ncbi.nlm.nih.gov/pub/lu/BioREx/datasets.zip
# Unzip the contents into the datasets folder and cleanly delete the zip archive
unzip datasets.zip
rm datasets.zip


# Create a folder named microsoft to store the pubmedbert model in
cd /home/jexia/biorex_replication/BioREx
mkdir microsoft
cd microsoft
# Download PubMedBERT model
pip install -U huggingface_hub
# Make and Navigate to the microsoft folder in BioREx
hf download microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract \
    --local-dir BiomedNLP-BiomedBERT-base-uncased-abstract

# Create a symbolic link
cd /home/jexia/biorex_replication/BioREx/microsoft
ln -s BiomedNLP-BiomedBERT-base-uncased-abstract \
      BiomedNLP-PubMedBERT-base-uncased-abstract
```
* Create the virtual environment
```bash
# Need to load python and arrow before setting up virtual environment
# Need to run this every time before launching the virtual environment
module load gcc arrow/24.0.0 python/3.12

# Create an isolated virtual environment named 'biorex_env'
virtualenv --no-download --system-site-packages biorex_env

# Activate the environment (your prompt will change to show '(biorex_env)')
source biorex_env/bin/activate

# Upgrade essential package management tools to prevent installation bugs
pip install --upgrade pip setuptools wheel
```
* Install package requirements
    * `avail_wheels tensorflow --all-versions` shows that versions 2.19.1 and 2.17.0 are available, version 2.18.0 is not available in the wheelhouse but I can install it directly from the internet. Do so for both tensorflow and tf_keras using this command. Make sure virtual environment is active and then run it directly: `PYTHONPATH=""  pip install tensorflow==2.18.0 tf_keras==2.18.0`
    * `protobuf == 5.29.2` and `tensorflow==2.17.0` are incompatible.  `tensorflow==2.17.0` requires `protobuf < 5.0.0`
    * Then comment out the first two lines in the requirements file and then proceed with below
```bash
# 1. Back up the original requirements file just in case
cp requirements.txt requirements.txt.bak

# 2. Delete the strict tensorflow version line from the file
nano requirements.txt

# 3. Cleanly install the rest of the dependencies from the file
# Make sure the virtual environment is active
pip install -r requirements.txt

pip install --no-index torch torchvision torchaudio
# To verify successful torch installation
python -c "import torch; print('Local PyTorch Version:', torch.__version__)"
```
* Check GPU connection
```bash
salloc --account=rrg-hroest_gpu --gres=gpu:h100:1 --cpus-per-task=2 --mem=16G --time=00:10:00

# 1. Load the cluster's system modules
module load gcc arrow/24.0.0 python/3.12 cuda/12.6

# 2. Activate your environment
source biorex_env/bin/activate

# Check PyTorch CUDA Access
python -c "import torch; print('CUDA Available:', torch.cuda.is_available()); print('GPU Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None')"

# Check a mock GPU calculation
python -c "import torch; x = torch.rand(5, 3).cuda(); print('Calculation successful on GPU:', x.device)"
```

* Take a small slice of the data for testing
    * I had initially just sliced the first 51 lines, but this might have sliced weird. Also! I did not slice the data in the ncbi_relation folder, those still had all the pmids --> I think this is what resulted in me getting zero predicted relations and 0s in the evaluation. The output was numeric scores/embeddings rather than relation classification decisions. 
    * Rather than subset by line, subset for only the pmid 15485686 in the test sets and only 10491763 in the train sets. I got zero predictions again this time but I think that is because it predicted "no relation" for all the pairs
```bash
# Move your main dataset folder to a backup name
mv datasets datasets_full

# Create the nested directory structure to match datasets_full
mkdir -p datasets/biorex/processed

# Slice the training set (first 51 lines)
# head -n 51 datasets_full/biorex/processed/train.tsv > datasets/biorex/processed/train.tsv
# Slice the test set (first 51 lines)
# head -n 51 datasets_full/biorex/processed/test.tsv > datasets/biorex/processed/test.tsv

# Slice the training and test sets by PMID
# Define your target PMID
TRAIN_PMID="10491763"
# Filter train and test sets by PMID
grep -E "^${TRAIN_PMID}"$'\t' datasets_full/biorex/processed/train.tsv > datasets/biorex/processed/train.tsv
grep -E "^${TRAIN_PMID}"$'\t' datasets_full/ncbi_relation/processed/train.tsv > datasets/ncbi_relation/processed/train.tsv

TEST_PMID="15485686"
grep -E "^${TEST_PMID}"$'\t' datasets_full/biorex/processed/test.tsv > datasets/biorex/processed/test.tsv
grep -E "^${TEST_PMID}"$'\t' datasets_full/ncbi_relation/processed/test.tsv > datasets/ncbi_relation/processed/test.tsv
# Slice the test PubTator file for TEST_PMID="15485686"
sed -n "/^${TEST_PMID}|/,/^$/p" datasets_full/ncbi_relation/Test.PubTator > datasets/ncbi_relation/Test.PubTator

# 1. Ensure the directory exists
mkdir -p datasets/ncbi_relation

# Copy the entire ncbi_relation folder from your full datasets backup
cp -r datasets_full/ncbi_relation datasets/
```
* Run on an interactive GPU session `salloc --account=rrg-hroest_gpu --gres=gpu:h100:1 --cpus-per-task=2 --mem=32G --time=00:20:00` 
    * Need to run `module load gcc arrow/24.0.0 python/3.12 cuda/12.6` and `source biorex_env/bin/activate` after activating the interactive session
    * Tried `mem=8G` but got an `out of memory` error, trying again with `mem=32G`
* `exit` is used to end an interactive session
* Encountered a numpy error - The code in BioREx was written using an older version of NumPy where np.float was valid. Since your cluster environment is running a newer version, it throws an AttributeError because np.float was removed in favor of Python's built-in float
    * In `/home/jexia/biorex_replication/BioREx/src/run_ncbi_rel_exp.py`, replace `np.float` with `float`
    * Ran the below code again after launching an interactive GPU session
    * Ran out of time in the interactive session, submitting a batch job instead
* The below job took 12 minutes to train
```bash
# 1. Load your modules
module load gcc arrow/24.0.0 python/3.12 cuda/12.6

# 2. Activate your environment
source biorex_env/bin/activate

# 3. Kick off the test
bash scripts/run_biorex_exp.sh 0
# Do the same but with a batch job, must run from the BioREx folder
sbatch ../jobs/submit_biorex.sh

# To cancel all my jobs:
scancel -u jexia
```
* This uses the full BioREx dataset for fine tuning which involves 10 epochs and 7.7k steps per epoch totalling 77k steps. It's taken more than 2 minutes per 10 steps. The estimated time needed to complete the entire fine tuning is 12 days. At 1 GPU, 4 CPU, 32GBs of memory
    * Cancelled the job to save on compute, there is still 2 hours left of my 6 hour job, there is no way its finishing
* What I really want is to just train on the biored dataset. I've pointed the training, dev, and test sets to the biored data only
* Did not finish running, to speed up the training:
    * `--num_train_epochs 3` (was 10 initially)
    * `--save_steps 500` (was 10 initially)
    * After this change, the total optimization steps decreased to 4.3k, but still it takes approximately 13.6s per step, and it would still take nearly 14h. There may be something wrong with the GPU which is expected to be a lot faster. Cancelled and reran with the below changes
* Added cudnn to the modules that I load when running the job: `module load gcc arrow/24.0.0 python/3.12 cuda/12.6 cudnn/9.10.0.56`
    * This still did not work, cancelled and added a diagnostic block to submit_biorex.sh to see if CUDA is working. It is working
* Removed `CUDA_VISIBLE_DEVICES=$cuda_visible_devices` and `cuda_visible_devices=$1` which overrode what slurm was doing. Also added `--fp16 true \`
    * Moving forward, I can also increase the number of CPUs from 4 to 8. Increasing to 8 means I have to wait longer for my job to start. Stick to 4 for now
* Install CUDA-enabled tensorflow, removed and reinstalled the virtual environment. This worked. Took only 10 minutes to finish training
    * Multi-class evaluation: F1-Score: 22.6% (Precision: 26.3%, Recall: 19.9%)
    * Binary-relation evaluation: F1-Score: 54.8% (Precision: 63.6%, Recall: 48.1%)
```bash
# Deactivate current env
deactivate

# Remove the old environment folder (replace 'myenv' with your env name)
rm -rf biorex_env

# 1. Load GCC and Python module
# module load gcc python/3.11
# Load multiple modules at once, without these modules loaded I have trouble installing the packages
module load gcc arrow/24.0.0 python/3.11 cuda/12.6

# 2. Create a clean virtual environment
virtualenv --no-download biorex_env

# 3. Activate the environment
source biorex_env/bin/activate

# 4. Install Compute Canada's pre-compiled, GPU-optimized TensorFlow FIRST
pip install --no-index tensorflow

# 5. Install the rest of your required packages
pip install tf-keras==2.19.0 transformers==4.47.1 accelerate==1.2.1 pandas==2.2.3 datasets==3.2.0 "sentencepiece!=0.1.92" protobuf==5.29.2 scispacy==0.5.5

# 6. Install the SciSpacy model directly from S3
pip install https://s3-us-west-2.amazonaws.com/ai2-s2-scispacy/releases/v0.5.4/en_core_sci_md-0.5.4.tar.gz

# 2. Install click
pip install click
```
* To improve scores. Changed `--num_train_epochs 3` to 10. Added `--learning_rate 2e-5 \` following the publication and `--warmup_ratio 0.1 \`
    * This took 30 minutes, approximately 3 times what it took initially. 
    * Multi-class evaluation: F1-Score: 51%
    * Binary-relation evaluation: F1-Score: 69%
* My folder under the projects folder (/home/jexia/projects/rrg-hroest/jexia) appeared so I moved everything there
    * Need to delete and re-make the virtual environment
```bash
# Command to copy over the files
rsync -avP /home/jexia/biorex_replication/ /home/jexia/projects/rrg-hroest/jexia/biorex_replication/

# Remove original folder
rm -rf /home/jexia/biorex_replication/
```


## 2026-07-28
### Objective
Train model using Gemini-generated triples and evaluate performance. 

### What I did
Using Gemini generated triples for the BioRED corpus:
* Make the format match the original BioRED dataset so it is suitable for training. Make sure entities match as well
* Evaluate the performance of this trained model on the Gemini Test set --> Expect this performance to be better because both are Gemini
* Evaluate the performance of this trained model on the original Test set --> Expect this performance to be worse. This is a control 

Created a new file `03_prepare_training_data.ipynb` and duplicated the `ncbi_relation` folder and the file contained, renaming it to `ncbi_relation_gemini_annotations`. I will edit the files in this folder directly (leave the PubTator files for now and focus on the processed .tsv files)
* Upload the formatted tsv files to compute canada
```powershell
scp -r "D:\Users\Jessica\kg-construction\data\00_raw\biorex\ncbi_relation_gemini_annotations\processed" jexia@fir.alliancecan.ca:/home/jexia/projects/rrg-hroest/jexia/biorex_replication/BioREx/datasets
```
```bash
mv processed ncbi_relation_gemini_annotations
```
* Made a copy of run_biorex_exp.sh and modified it so the files it pointed to were the Gemini annotated files
* Lost the files in the jobs folder, had to recreate the submit_biorex.sh file
* The job was not running until I upped the memory to 64G and CPU to 8
    * From the BioREx folder, run this: `sbatch ../jobs/submit_biorex_3.sh`
* The results of the first iteration was very bad
    * Overall F1-Score: 30.09%
    * Overall Precision: 33.63%
    * Overall Recall: 27.23%
* Looked into the relation-type distribution in each train, test, validate dataset
    * Found out I had over-written the test dataset of the original raw data, resulting in there being no difference between the original test dataset and my Gemini ones. 
    * Because of this, I re-downloaded the original dataset: `curl -L -O https://ftp.ncbi.nlm.nih.gov/pub/lu/BioREx/datasets.zip`
    * This shouldnt affect the results, assuming the Gemini generated test set was the one I used in the evaluation
* I tried again but the performance is still very poor
    * Overall F1-Score: 24.86%
    * Overall Precision: 32.34%
    * Overall Recall: 20.19%
* I think there may just be too many negatives, I will set `--use_balanced_neg true \` and `--max_neg_scale 2 \` in `run_biorex_exp_gemini.sh`
    * Originally it was `--use_balanced_neg false \`
    * This samples the negative examples such that the ratio of negative to positive examples is 2:1. Currently it is around 4.5:1 for the original BioRED dataset and 5.8:1 for my current Gemini dataset
    * Results in results_20260730_092808
        * Precision, Recall, and F1 also increased dramatically: 46%, 52%, 49%
* Decreased further to `--max_neg_scale 1 \` and reran `run_biorex_exp_gemini.sh`, all else kept the same as previous
    * Results in results_20260730_101832
    * This decreased performance. Precision fell slightly while Recall increased.
    * Precision, Recall, and F1: 42%, 56%, 48%
* Re-ran these two negative example settings on the original BioRED dataset
    * First job is `--use_balanced_neg false \` in `results_biored_only_20260730_121354`
        * `sbatch ../jobs/submit_biorex_original.sh`
        * JOBID 51837436 --> finished after (need to change the naming so that I can match the output not only to the time but to the JOBID)
        * Results saved here: results_biored_only_20260730_131534/ --> these results are unreliable because the two files overwrote each other
        * Reran JOBID 51993338 --> results saved to results_biored_only_original_20260730_200021/
            * 0.51, 0.51, 0.51; binned: 0.68, 0.68, 0.68
    * Second job is `--use_balanced_neg true \` and `--max_neg_scale 2 \` in `results_biored_only_20260730_122823`
        * `sbatch ../jobs/submit_biorex_neg_reduced.sh`
        * JOBID 51837437
        * Results saved here: results_biored_only_20260730_131534/ --> these results are unreliable because the two files overwrote each other
        * Reran JOBID 51993822 --> results saved to results_biored_only_20260730_200453/
            * 0.52, 0.53, 0.52; binned: 0.79, 0.71, 0.71


## 2026-07-31
### Objective
Train model using Gemini-generated triples and evaluate performance. Vary the number of negative examples used in training. 

### What I did
* I've performed many iterations and have not stayed organized. Put my code and output outside the BioREx folder
* Not working, went back to re-installing the virtual environment
* First verify aspects of the code to make sure it is working:
    * `salloc --account=rrg-hroest --gres=gpu:h100:1 --cpus-per-task=4 --mem=32G --time=00:30:00`
    ```bash
    cd /project/6049253/jexia/biorex_replication
    source biorex_env/bin/activate

    unset USE_TF
    unset USE_TORCH

    python -c "import tensorflow as tf; print('\n>>> GPU Detected:', tf.config.list_physical_devices('GPU'))"

    cd /project/6049253/jexia/biorex_replication/BioREx
    python -c 'import sys; sys.path.append("src"); import run_ncbi_rel_exp; print("\n>>> Imports successful!")'

    cd /project/6049253/jexia/biorex_replication/BioREx

    python src/run_ncbi_rel_exp.py \
    --task_name biorex \
    --train_file datasets/ncbi_relation_gemini_annotations/processed/train.tsv \
    --dev_file datasets/ncbi_relation_gemini_annotations/processed/dev.tsv \
    --test_file datasets/ncbi_relation_gemini_annotations/processed/test.tsv \
    --use_balanced_neg false \
    --max_neg_scale 0 \
    --to_add_tag_as_special_token true \
    --model_name_or_path microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract \
    --output_dir test_interactive_run \
    --num_train_epochs 1 \
    --learning_rate 2e-5 \
    --per_device_train_batch_size 16 \
    --per_device_eval_batch_size 32 \
    --do_train \
    --fp16 true \
    --logging_steps 5 \
    --save_steps 50 \
    --overwrite_output_dir true \
    --max_seq_length 512
    ```
* Note: if use_balanced_neg is set to false, the number after does not matter, that code block is skipped
#### [Job 52880918] - Gemini annotations all neg
* **Command:** `sbatch scripts/submit_run_biored_gemini_neg_scale.sh gemini false 0 "Gemini annotations all neg"`

#### [Job 52893913] - Gemini annotations neg reduced 2:1
* **Command:** `sbatch scripts/submit_run_biored_gemini_neg_scale.sh gemini true 2 "Gemini annotations neg reduced 2:1"`

#### [Job 52893973] - BioRED annotations all neg
* **Command:** `sbatch scripts/submit_run_biored_gemini_neg_scale.sh biored false 0 "BioRED annotations all neg"`

#### [Job 52894019] - BioRED annotations neg reduced 2:1
* **Command:** `sbatch scripts/submit_run_biored_gemini_neg_scale.sh biored true 2 "BioRED annotations neg reduced 2:1"`


## 2026-08-04
### Objective
Download and prepare PubMedQA data for inference using trained model. 

### What I did
* Downloaded the PubMedQA dataset from Github
```bash
mkdir -p data/pubmedqa/raw data/pubmedqa/processed

curl -o data/pubmedqa/raw/ori_pqal.json \
  https://raw.githubusercontent.com/pubmedqa/pubmedqa/master/data/ori_pqal.json
```
* Process the data to prepare it for inference using scripts/prepare_pubmedqa_inference.py
    * Navigate to the biorex_replication parent folder and run `python scripts/prepare_pubmedqa_inference.py`
    * This creates a tsv file called `test.tsv` located here `biorex_replication/data/pubmedqa/processed` which contains the columns pmid, text and question. The text is what is used for inference. Excludes the conclusion. 
* Fetch the pmids which I will extract entities from `biorex_replication/scripts/extract_pmids.py`
    * `python scripts/extract_pmids.py --test_tsv data/pubmedqa/processed/test.tsv --out_pmids data/pubmedqa/processed/pmids.txt`
* With these PMIDs, fetch the PubTator files
    * Need to install the requests package ```pip install requests```
    * Created `scripts/fetch_pubtator.py`
    * `python scripts/fetch_pubtator.py --pmids data/pubmedqa/processed/pmids.txt --out_pubtator data/pubmedqa/raw/pubmedqa_entities.PubTator`
* The test file it expects is a TSV relation-pair format with columns for PMID, entity types, entity identifiers, and the tagged sentence text. 
* From the PubTator files, fetch all unique entity types
    * `awk -F'\t' 'NF==6 {print $5}' data/pubmedqa/raw/pubmedqa_entities.PubTator | sort | uniq -c`
    * What was returned:
        ```
        17 CellLine
        1798 Chemical
        1 Chromosome
        7 DNAMutation
        9942 Disease
        876 Gene
        5 ProteinMutation
        25 SNP
        4715 Species
        ```
* I am only interested in Gene, Chemical, Disease entity types. 
* Only interested in these entity type pairs:
    ```
                Entity_A           Entity_B
    0  GeneOrGeneProduct  GeneOrGeneProduct
    1     ChemicalEntity  GeneOrGeneProduct
    2     ChemicalEntity            Disease
    3     ChemicalEntity     ChemicalEntity
    4            Disease  GeneOrGeneProduct
    ```
* These are the only entity pairs present in BioRED. The Pubtator annotation entity types need to be mapped
    ```
    sed -e 's/\tGene\t/\tGeneOrGeneProduct\t/g' \
    -e 's/\tChemical\t/\tChemicalEntity\t/g' \
    -e 's/\tDisease\t/\tDiseaseOrPhenotypicFeature\t/g' \
    data/pubmedqa/raw/pubmedqa_entities.PubTator > data/pubmedqa/processed/pubmedqa_entities_litcoin.PubTator
    ```
* Convert the PubTator file to tsv
    ``` bash
    python -m spacy download en_core_web_sm

    salloc --account=rrg-hroest --gres=gpu:h100:1 --cpus-per-task=4 --mem=32G --time=01:30:00

    module load gcc arrow/24.0.0 python/3.11 cuda/12.6
    source biorex_env/bin/activate

    cd BioREx/src/dataset_format_converter/

    python -c "
    from convert_pubtator_2_tsv import convert_pubtator_to_tsv_file

    tag_mapping = {
        'Gene': 'GeneOrGeneProduct',
        'Chemical': 'ChemicalEntity',
        'Disease': 'DiseaseOrPhenotypicFeature'
    }

    litcoin_pairs = {
        ('GeneOrGeneProduct', 'GeneOrGeneProduct'),
        ('ChemicalEntity', 'GeneOrGeneProduct'),
        ('ChemicalEntity', 'DiseaseOrPhenotypicFeature'),
        ('ChemicalEntity', 'ChemicalEntity'),
        ('DiseaseOrPhenotypicFeature', 'GeneOrGeneProduct')
    }

    convert_pubtator_to_tsv_file(
        in_pubtator_file='../../../data/pubmedqa/raw/pubmedqa_entities.PubTator',
        out_tsv_file='../../../data/pubmedqa/processed/pubmedqa_inference_ready.tsv',
        src_tgt_pairs=litcoin_pairs,
        spacy_model='en_core_web_sm',
        has_end_tag=True,
        task_tag='[LitCoin]',
        normalized_type_dict=tag_mapping,
        re_id_spliter_str=r'\,',
        to_sentence_level=True
    )
    "
    ```
* Run inference. Created a script called submit_pubmedqa_inference.sh. Outputs both a tsv logits file and a PubTator file containing the entities and relations
    * `sbatch scripts/submit_pubmedqa_inference.sh exp_20260804_103551_job52880918_gemini_balfalse_neg0`
    * `sbatch scripts/submit_pubmedqa_inference.sh exp_20260804_113027_job52893913_gemini_baltrue_neg2`
    * `sbatch scripts/submit_pubmedqa_inference.sh exp_20260804_113359_job52893973_biored_balfalse_neg0`
    * `sbatch scripts/submit_pubmedqa_inference.sh exp_20260804_113359_job52894019_biored_baltrue_neg2`

* Convert tsv file to pubtator. Created a script called submit_to_pubtator.sh
    * `sbatch scripts/submit_to_pubtator.sh exp_20260804_103551_job52880918_gemini_balfalse_neg0`
    * `sbatch scripts/submit_to_pubtator.sh exp_20260804_113027_job52893913_gemini_baltrue_neg2`
    * `sbatch scripts/submit_to_pubtator.sh exp_20260804_113359_job52893973_biored_balfalse_neg0`
    * `sbatch scripts/submit_to_pubtator.sh exp_20260804_113359_job52894019_biored_baltrue_neg2`
    
  

python BioREx/src/utils/run_pubtator_eval.py --exp_option 'to_pubtator' \
    --in_test_pubtator_file data/pubmedqa/raw/pubmedqa_entities.PubTator \
    --in_test_tsv_file data/pubmedqa/processed/pubmedqa_inference_ready.tsv \
    --in_pred_tsv_file /home/jexia/projects/rrg-hroest/jexia/biorex_replication/experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results/test_results.tsv \
    --out_pred_pubtator_file /home/jexia/projects/rrg-hroest/jexia/biorex_replication/experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results/predict.pubtator



module load gcc arrow/24.0.0 python/3.11 cuda/12.6
source biorex_env/bin/activate

export PYTHONPATH="/home/jexia/projects/rrg-hroest/jexia/biorex_replication/BioREx:/home/jexia/projects/rrg-hroest/jexia/biorex_replication/BioREx/src:/home/jexia/projects/rrg-hroest/jexia/biorex_replication/BioREx/src/utils:/home/jexia/projects/rrg-hroest/jexia/biorex_replication/BioREx/src/dataset_format_converter:${PYTHONPATH}"

python BioREx/src/utils/run_pubtator_eval.py --exp_option 'to_pubtator' \
    --in_test_pubtator_file data/pubmedqa/raw/pubmedqa_entities.PubTator \
    --in_test_tsv_file data/pubmedqa/processed/pubmedqa_inference_ready.tsv \
    --in_pred_tsv_file /home/jexia/projects/rrg-hroest/jexia/biorex_replication/experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results/test_results.tsv \
    --out_pred_pubtator_file /home/jexia/projects/rrg-hroest/jexia/biorex_replication/experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results/predict.pubtator

* This script works, calculates the distibution of relation types directly from the tsv file.
    * After running the above code to perform inference on the PubMedQA dataset, the results returned 100% No Relation
    ```bash
    python scripts/check_pred_distribution.py \
    experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results/test_results.tsv \
    experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/model

    python scripts/check_pred_distribution.py \
    experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/results/out_results.tsv \
    experiments/exp_20260804_103551_job52880918_gemini_balfalse_neg0/model

    python scripts/check_pred_distribution.py \
    experiments/exp_20260804_113027_job52893913_gemini_baltrue_neg2/pubmedqa_inference_results/test_results.tsv \
    experiments/exp_20260804_113027_job52893913_gemini_baltrue_neg2/model

    python scripts/check_pred_distribution.py \
    experiments/exp_20260804_113359_job52893973_biored_balfalse_neg0/pubmedqa_inference_results/test_results.tsv \
    experiments/exp_20260804_113359_job52893973_biored_balfalse_neg0/model

    python scripts/check_pred_distribution.py \
    experiments/exp_20260804_113359_job52894019_biored_baltrue_neg2/pubmedqa_inference_results/test_results.tsv \
    experiments/exp_20260804_113359_job52894019_biored_baltrue_neg2/model

    exp_20260804_113359_job52893973_biored_balfalse_neg0

    exp_20260804_113359_job52894019_biored_baltrue_neg2
    ```


* The script scripts/submit_pubmedqa_inference.sh performs the inference given a specific model
    * `sbatch scripts/submit_pubmedqa_inference.sh exp_20260731_104435_job52173517_gemini_baltrue_neg2`


* Link Compute Canada account to Github to backup code
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"

# Display the public key
cat ~/.ssh/id_ed25519.pub

# Add the key to Github
# Settings > SSH and GPG keys > New SSH key

ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts

ssh -T git@github.com
Hi jess-xia! You've successfully authenticated, but GitHub does not provide shell access.

```
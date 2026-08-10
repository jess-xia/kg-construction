import json
import pandas as pd
import os

# Paths
INPUT_JSON = "data/pubmedqa/raw/ori_pqal.json"
OUTPUT_TSV = "data/pubmedqa/processed/test.tsv"

os.makedirs("data/pubmedqa/processed", exist_ok=True)

with open(INPUT_JSON, "r") as f:
    pqa_data = json.load(f)

rows = []

for pmid, item in pqa_data.items():
    # Flatten the context sentences into a single abstract text string
    abstract_text = " ".join(item["CONTEXTS"])
    question = item["QUESTION"]
    
    # Format according to BioREx prediction input expectations
    # (PMID, Text, and placeholder entity structural fields)
    rows.append({
        "pmid": pmid,
        "text": abstract_text,
        "question": question
    })

df = pd.DataFrame(rows)
df.to_csv(OUTPUT_TSV, sep="\t", index=False)
print(f"Successfully processed {len(df)} PubMedQA records to {OUTPUT_TSV}")

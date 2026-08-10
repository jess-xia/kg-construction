#!/usr/bin/env python
"""
Check the predicted label distribution from a BioREx test_results.tsv
(raw logits, one row per example) against the model's id2label mapping.

Usage:
    python check_pred_distribution.py <test_results.tsv> <model_dir>
"""
import sys
import json
import pandas as pd

def main():
    if len(sys.argv) != 3:
        print("Usage: python check_pred_distribution.py <test_results.tsv> <model_dir>")
        sys.exit(1)

    results_file = sys.argv[1]
    model_dir = sys.argv[2]

    logits = pd.read_csv(results_file, sep="\t", header=None)
    print(f"Loaded {len(logits)} rows, {logits.shape[1]} logit columns")

    with open(f"{model_dir}/config.json") as f:
        config = json.load(f)
    id2label = {int(k): v for k, v in config["id2label"].items()}

    preds = logits.values.argmax(axis=1)
    pred_labels = [id2label[i] for i in preds]

    counts = pd.Series(pred_labels).value_counts()
    pct = (counts / len(pred_labels) * 100).round(2)

    print("\nPredicted label distribution:")
    for label in counts.index:
        print(f"  {label:25s} {counts[label]:6d}  ({pct[label]}%)")

if __name__ == "__main__":
    main()

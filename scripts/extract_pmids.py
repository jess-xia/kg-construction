import argparse

def extract_pmids(test_tsv_path, out_pmids_path):
    pmids = set()
    with open(test_tsv_path, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.rstrip('\n').split('\t')
            if parts and parts[0]:
                val = parts[0].strip()
                
                # Check 1: Skip known header strings
                if val.lower() in {'pmid', 'id', 'pubmed_id', 'pubmedid'}:
                    continue
                
                # Check 2: Only add if it consists purely of digits
                if val.isdigit():
                    pmids.add(val)

    with open(out_pmids_path, 'w', encoding='utf-8') as f_out:
        for pmid in sorted(pmids, key=int):  # Sort numerically
            f_out.write(f"{pmid}\n")

    print(f"Extracted {len(pmids)} valid numeric PMIDs to {out_pmids_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--test_tsv", required=True)
    parser.add_argument("--out_pmids", required=True)
    args = parser.parse_args()
    extract_pmids(args.test_tsv, args.out_pmids)

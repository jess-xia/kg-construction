import argparse
import time
import requests

API_URL = "https://www.ncbi.nlm.nih.gov/research/pubtator3-api/publications/export/pubtator"

def batch_list(iterable, batch_size):
    """Yield successive batch_size chunks from iterable."""
    for i in range(0, len(iterable), batch_size):
        yield iterable[i:i + batch_size]

def fetch_pubtator_data(pmids_path, out_pubtator_path, batch_size=100):
    # Load PMIDs
    with open(pmids_path, 'r', encoding='utf-8') as f:
        pmids = [line.strip() for line in f if line.strip().isdigit()]

    print(f"Loaded {len(pmids)} PMIDs to fetch.")

    fetched_count = 0
    with open(out_pubtator_path, 'w', encoding='utf-8') as f_out:
        for i, batch in enumerate(batch_list(pmids, batch_size)):
            # Form GET parameters with comma-separated PMIDs
            params = {
                "pmids": ",".join(batch)
            }

            try:
                # Must be requests.get
                response = requests.get(API_URL, params=params, timeout=30)
                
                if response.status_code == 200:
                    content = response.text
                    if content.strip():
                        f_out.write(content)
                        if not content.endswith('\n'):
                            f_out.write('\n')
                        fetched_count += len(batch)
                        print(f"Batch {i + 1}: Successfully fetched {len(batch)} PMIDs ({fetched_count}/{len(pmids)})")
                    else:
                        print(f"Batch {i + 1}: Received empty response from API (PMIDs might not exist in PubTator3)")
                else:
                    print(f"Batch {i + 1}: Failed with status code {response.status_code} - {response.text[:100]}")
            except Exception as e:
                print(f"Batch {i + 1}: Error fetching PMIDs -> {e}")

            # Respect PubTator limit (max 3 requests per second)
            time.sleep(0.4)

    print(f"\nDone! Raw PubTator data saved to {out_pubtator_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch PubTator files from NCBI API using PMID list.")
    parser.add_argument("--pmids", required=True, help="Path to input pmids.txt")
    parser.add_argument("--out_pubtator", required=True, help="Path to output .PubTator file")
    args = parser.parse_args()

    fetch_pubtator_data(args.pmids, args.out_pubtator)

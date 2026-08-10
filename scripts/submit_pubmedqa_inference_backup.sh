#!/bin/bash
#SBATCH --job-name=biorex_pubmedqa_infer
#SBATCH --output=experiments/logs/slurm_%x_%j.out
#SBATCH --error=experiments/logs/slurm_%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:h100:1
#SBATCH --mem=64G
#SBATCH --time=00:30:00
#SBATCH --account=rrg-hroest
module load gcc arrow/24.0.0 python/3.11 cuda/12.6
cd /home/jexia/projects/rrg-hroest/jexia/biorex_replication
source biorex_env/bin/activate
echo "=== Batch job diagnostics ==="
hostname
nvidia-smi
echo "SLURM_JOB_ID=$SLURM_JOB_ID"
echo "============================="

# Usage: sbatch submit_pubmedqa_inference.sh <exp_name>
# e.g.:  sbatch submit_pubmedqa_inference.sh exp_20260804_103551_job52880918_gemini_balfalse_neg0
exp_name=${1:?"Missing arg 1: exp_name (e.g. exp_20260804_103551_job52880918_gemini_balfalse_neg0)"}
exp_dir="/home/jexia/projects/rrg-hroest/jexia/biorex_replication/experiments/${exp_name}"

mkdir -p experiments/logs
mkdir -p "${exp_dir}/pubmedqa_inference_results"
python BioREx/src/run_ncbi_rel_exp.py \
    --task_name biorex \
    --do_predict \
    --test_file data/pubmedqa/processed/pubmedqa_inference_ready.tsv \
    --model_name_or_path "${exp_dir}/model" \
    --label_column_id 9 \
    --text_column_id 7 \
    --max_seq_length 512 \
    --output_dir "${exp_dir}/pubmedqa_inference_results"

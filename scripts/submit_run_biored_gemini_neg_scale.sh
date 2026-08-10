#!/bin/bash
#SBATCH --job-name=biorex_exp
#SBATCH --output=experiments/logs/slurm_%x_%j.out
#SBATCH --error=experiments/logs/slurm_%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:h100:1
#SBATCH --mem=64G
#SBATCH --time=01:30:00
#SBATCH --account=rrg-hroest

mkdir -p experiments/logs

module load gcc arrow/24.0.0 python/3.11 cuda/12.6

cd /project/6049253/jexia/biorex_replication
source biorex_env/bin/activate

echo "=== Batch job diagnostics ==="
hostname
date
nvidia-smi
echo "SLURM_JOB_ID=$SLURM_JOB_ID"
echo "============================="

unset USE_TF
unset USE_TORCH

bash scripts/run_biored_gemini_neg_scale.sh "$@"

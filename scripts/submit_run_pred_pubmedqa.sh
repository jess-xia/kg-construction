#!/bin/bash
#SBATCH --job-name=biorex_pred
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

mkdir -p experiments/logs
bash scripts/run_pred_pubmedqa.sh "$@"

#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SLURM_JOB_ID=${SLURM_JOB_ID:-"local"}
task_name="biorex"

# 0. Command line args
dataset_type=${1:-"gemini"}
use_balanced_neg=${2:-"true"}
max_neg_scale=${3:-"1"}
notes=${4:-"No notes provided"}

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Define unified experiment folder name and full path
EXP_ID="exp_${TIMESTAMP}_job${SLURM_JOB_ID}_${dataset_type}_bal${use_balanced_neg}_neg${max_neg_scale}"
EXP_DIR="${PROJECT_ROOT}/experiments/${EXP_ID}"

# Define subdirectories inside the single experiment folder
output_dir="${EXP_DIR}/model"
results_dir="${EXP_DIR}/results"

mkdir -p "${output_dir}"
mkdir -p "${results_dir}"

pre_train_model="${PROJECT_ROOT}/BioREx/microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract"

# Save meta.txt inside the root experiment folder
cat << EOF > "${EXP_DIR}/meta.txt"
EXP_ID: ${EXP_ID}
Timestamp: ${TIMESTAMP}
Script: run_biored_gemini_neg_scale.sh
Dataset: ${dataset_type}
Use Balanced Negatives: ${use_balanced_neg}
Max Neg Scale: ${max_neg_scale}
Pretrained Model: ${pre_train_model}
Notes: ${notes}
EOF

# 1. Input datasets (relative to BioREx directory)
if [ "$dataset_type" = "biored" ]; then
    in_train_tsv_file="datasets/ncbi_relation/processed/train.tsv"
    in_dev_tsv_file="datasets/ncbi_relation/processed/dev.tsv"
    in_test_tsv_file="datasets/ncbi_relation/processed/test.tsv"
else
    in_train_tsv_file="datasets/ncbi_relation_gemini_annotations/processed/train.tsv"
    in_dev_tsv_file="datasets/ncbi_relation_gemini_annotations/processed/dev.tsv"
    in_test_tsv_file="datasets/ncbi_relation_gemini_annotations/processed/test.tsv"
fi

# Move into BioREx directory so imports and dataset paths resolve naturally
cd "${PROJECT_ROOT}/BioREx"

# Clean TF / PyTorch environment variables
unset USE_TF
unset USE_TORCH

python src/run_ncbi_rel_exp.py \
  --task_name "${task_name}" \
  --train_file "${in_train_tsv_file}" \
  --dev_file "${in_dev_tsv_file}" \
  --test_file "${in_test_tsv_file}" \
  --use_balanced_neg "${use_balanced_neg}" \
  --max_neg_scale "${max_neg_scale}" \
  --to_add_tag_as_special_token true \
  --model_name_or_path "${pre_train_model}" \
  --output_dir "${output_dir}" \
  --num_train_epochs 10 \
  --learning_rate 2e-5 \
  --warmup_ratio 0.1 \
  --per_device_train_batch_size 16 \
  --per_device_eval_batch_size 32 \
  --do_train \
  --do_predict \
  --fp16 true \
  --logging_steps 10 \
  --evaluation_strategy steps \
  --save_steps 500 \
  --overwrite_output_dir false \
  --max_seq_length 512

# 2. Save prediction and evaluation artifacts inside results/
cp "${output_dir}/test_results.tsv" "${results_dir}/out_results.tsv"

python src/utils/run_pubtator_eval.py --exp_option 'biored_eval' \
  --in_gold_tsv_file "${in_test_tsv_file}" \
  --in_pred_tsv_file "${results_dir}/out_results.tsv" \
  --out_bin_result_file "${results_dir}/out_bin_results.txt" \
  --out_result_file "${results_dir}/out_results.txt" \
  --out_pred_pubtator_file "${results_dir}/out_bin_results.pubtator"

echo "Run completed! Artifacts saved to ${EXP_DIR}/"

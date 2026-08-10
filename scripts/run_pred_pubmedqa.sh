#!/bin/bash
set -e

# Make sure we're running from inside BioREx/, since the paths below
# (src/..., etc.) are relative to that directory.
cd "$(dirname "$0")/../BioREx"

# ------------------------------------------------------------------------------
# Args
# Usage: bash scripts/run_pred_pubmedqa.sh <in_pubtator_file> <model_dir>
#
#   in_pubtator_file : path to the input PubTator file
#   model_dir        : path to a trained model dir, e.g.
#                       .../experiments/exp_.../model
#                       Results are written to pubmedqa_inference_results/
#                       under that experiment's root (one level up from model_dir).
# ------------------------------------------------------------------------------
in_pubtator_file=${1:?"Missing arg 1: in_pubtator_file"}
model_dir=${2:?"Missing arg 2: model_dir (path to trained model)"}

# results go under the experiment dir (one level up from model_dir),
# e.g. .../exp_20260804_103551_job52880918_gemini_balfalse_neg0/pubmedqa_inference_results
exp_dir="$(dirname "${model_dir}")"
results_dir="${exp_dir}/pubmedqa_inference_results"
mkdir -p "${results_dir}"

out_tsv_file="${results_dir}/out_processed.tsv"
out_pubtator_file="${results_dir}/predict.pubtator"
pre_train_model="${model_dir}"

# ------------------------------------------------------------------------------
# 1. Convert PubTator -> TSV
# ------------------------------------------------------------------------------
echo 'Converting the dataset into BioREx input format'
python src/dataset_format_converter/convert_pubtator_2_tsv.py \
    --exp_option biored_pred \
    --in_pubtator_file "${in_pubtator_file}" \
    --out_tsv_file "${out_tsv_file}"

# ------------------------------------------------------------------------------
# 2. Run inference with the specified model
# ------------------------------------------------------------------------------
echo "Generating RE predictions"
python src/run_ncbi_rel_exp.py \
  --task_name "biorex" \
  --test_file "${out_tsv_file}" \
  --use_balanced_neg false \
  --to_add_tag_as_special_token true \
  --model_name_or_path "${pre_train_model}" \
  --output_dir "${results_dir}/biorex_model_inference" \
  --num_train_epochs 10 \
  --per_device_train_batch_size 16 \
  --per_device_eval_batch_size 32 \
  --do_predict \
  --logging_steps 10 \
  --evaluation_strategy steps \
  --save_steps 10 \
  --overwrite_output_dir \
  --max_seq_length 512

# ------------------------------------------------------------------------------
# 3. Convert predictions back to PubTator format
# ------------------------------------------------------------------------------
cp "${results_dir}/biorex_model_inference/test_results.tsv" "${results_dir}/out_biorex_results.tsv"
python src/utils/run_pubtator_eval.py --exp_option 'to_pubtator' \
  --in_test_pubtator_file "${in_pubtator_file}" \
  --in_test_tsv_file "${out_tsv_file}" \
  --in_pred_tsv_file "${results_dir}/out_biorex_results.tsv" \
  --out_pred_pubtator_file "${out_pubtator_file}"

echo "Done. Results saved to ${results_dir}/"

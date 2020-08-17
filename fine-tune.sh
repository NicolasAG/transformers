#!/usr/bin/env bash


# get organization / user / account name
export ORG_NAME=$(eai organization get --fields name --no-header)
export USER_NAME=$(eai user get --fields name --no-header)
export ACCOUNT_NAME=$(eai account get --fields name --no-header)
#export ACCOUNT_ID=$(eai account get --fields id --no-header)
export ACCOUNT_ID=$ORG_NAME.$ACCOUNT_NAME

echo "account id: $ACCOUNT_ID"

eai_code="code_hf_transformers"

echo "pushing all files to ${eai_code} ..."
# ignore models, .git, __pycache__, current and parent folders
all_files=$(ls -I . -I .. -I __pycache__ -I .git)
for f in $all_files
do
  eai data push "${eai_code}" $f:$f
done
echo "done. now submitting job..."

: '
eai job submit \
    --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
    --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
    --cpu 4 \
    --mem 32 \
    --gpu 2 \
    --gpu-mem 8 \
    --restartable \
    -- bash -c "cd /hf_transformers \
                && pip install . --no-warn-script-location \
                && pip install -r ./examples/requirements.txt --no-warn-script-location \
                && cd /hf_transformers/examples/language-modeling \
                && python run_language_modeling.py \
                      --output_dir=model/test \
                      --model_type=gpt2 \
                      --model_name_or_path=gpt2 \
                      --do_train \
                      --train_data_file=../../data/test.txt \
                      --per_device_train_batch_size=16 \
                      --per_device_eval_batch_size=16 \
                      --gradient_accumulation_steps=8 \
                      --num_train_epochs=1 \
                      --line_by_line \
                && echo FINE-TUNING DONE. \
                && echo ================= \
                && echo BEGIN GENERATION. \
                && cd /hf_transformers/examples/text-generation \
                && python run_generation.py \
                    --model_type=gpt2 \
                    --model_name_or_path=/hf_transformers/examples/language-modeling/model/test \
                    --prompt=./test-1.2-facts-anon.txt \
                    --length=256 \
                    --temperature=0.7 \
                    --k=30 \
                    --p=0.9 \
                    --out_file=./test-1.2-facts-anon_sp-predictions.txt
    "
eai job log -f --last
'
try=12

for m1 in "np" # "sp" "spr" # "lp" "lpr"
do
  for m2 in "facts" # "amt"
  do
    eai job submit \
    --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
    --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
    --cpu 6 \
    --mem 64 \
    --gpu 4 \
    --gpu-mem 32 \
    --name "finetune_hf_gpt2_${m1}_${m2}_anon_try${try}" \
    --restartable \
    -- bash -c "cd hf_transformers \
                && pip install . --no-warn-script-location \
                && pip install -r ./examples/requirements.txt --no-warn-script-location \
                && cd examples/language-modeling \
                && python run_language_modeling.py \
                      --output_dir=/hf_transformers/examples/language-modeling/models/${m1}-${m2}-anon \
                      --model_type=gpt2 \
                      --model_name_or_path=gpt2 \
                      --patience=20 \
                      --num_train_epochs=1 \
                      --do_train \
                      --train_data_file=/hf_transformers/data/${m1}-${m2}-anon[train].txt \
                      --do_eval \
                      --eval_data_file=/hf_transformers/data/${m1}-${m2}-anon[valid].txt \
                      --save_total_limit=1 \
                      --per_device_train_batch_size=8 \
                      --per_device_eval_batch_size=8 \
                      --gradient_accumulation_steps=16 \
                      --line_by_line \
                      --dataloader_drop_last
    "
  done
done

eai job log -f --last

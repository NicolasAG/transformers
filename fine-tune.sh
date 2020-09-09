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

try=35

for m1 in "lpr" # "np" "sp" "spr" "lp" "lpr"
do
  if [ $m1 == "sp" ]
  then
    mode="short-proof"
    bs=8
    acc=16
  elif [ $m1 == "spr" ]
  then
    mode="short-proof-rev"
    bs=8
    acc=16
  elif [ $m1 == "lp" ]
  then
    mode="long-proof"
    bs=4
    acc=16
  elif [ $m1 == "lpr" ]
  then
    mode="long-proof-rev"
    bs=4
    acc=16
  else
    mode="no-proof"
    bs=8
    acc=16
  fi
  for m2 in "facts" # "facts" "amt"
  do
    # FINETUNE
    eai job submit \
    --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
    --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
    --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
    --cpu 8 \
    --mem 64 \
    --gpu 4 \
    --gpu-mem 32 \
    --name "finetune_hf_gpt2_${m1}_${m2}_anon_try${try}" \
    --restartable \
    -- bash -c "cd hf_transformers \
                && export PYTHONPATH=/hf_transformers/src:/hf_transformers/install \
                && cd examples/language-modeling \
                && python run_language_modeling.py \
                      --output_dir=/models/clutrr/1_${mode}_${m2}_2_4_6/hf-gpt_anon \
                      --model_type=gpt2 \
                      --model_name_or_path=gpt2 \
                      --do_train \
                      --train_data_file=/hf_transformers/data/${m1}-${m2}-anon[train].txt \
                      --eval_data_file=/hf_transformers/data/${m1}-${m2}-anon[valid].txt \
                      --evaluate_during_training \
                      --patience=20 \
                      --save_total_limit=22 \
                      --num_train_epochs=999 \
                      --save_steps=540 \
                      --eval_steps=540 \
                      --logging_steps=540 \
                      --per_device_train_batch_size=${bs} \
                      --per_device_eval_batch_size=${bs} \
                      --gradient_accumulation_steps=${acc} \
                      --line_by_line \
                      --dataloader_drop_last \
                      --prediction_loss_only
    "
    # FROM SCRATCH (fs)
    : '
    eai job submit \
    --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
    --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
    --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
    --cpu 8 \
    --mem 64 \
    --gpu 4 \
    --gpu-mem 32 \
    --name "train_hf_gpt2_fs_${m1}_${m2}_anon_try${try}" \
    --restartable \
    -- bash -c "cd hf_transformers \
                && export PYTHONPATH=/hf_transformers/src:/hf_transformers/install \
                && cd examples/language-modeling \
                && python run_language_modeling.py \
                      --output_dir=/models/clutrr/1_${mode}_${m2}_2_4_6/hf-gpt-fs_anon \
                      --model_type=gpt2 \
                      --tokenizer_name=gpt2 \
                      --do_train \
                      --train_data_file=/hf_transformers/data/${m1}-${m2}-anon[train].txt \
                      --eval_data_file=/hf_transformers/data/${m1}-${m2}-anon[valid].txt \
                      --evaluate_during_training \
                      --patience=20 \
                      --save_total_limit=22 \
                      --num_train_epochs=999 \
                      --save_steps=540 \
                      --eval_steps=540 \
                      --logging_steps=540 \
                      --per_device_train_batch_size=${bs} \
                      --per_device_eval_batch_size=${bs} \
                      --gradient_accumulation_steps=${acc} \
                      --line_by_line \
                      --dataloader_drop_last \
                      --prediction_loss_only
    "
    '
  done
done

# eai job log -f --last

# export PYTHONPATH=/hf_transformers/install && export TMPDIR=/hf_transformers/install \
# && pip install --cache-dir=/hf_transformers/install --build /hf_transformers/install --target /hf_transformers/install --upgrade . --no-warn-script-location \
# && pip install --cache-dir=/hf_transformers/install --build /hf_transformers/install --target /hf_transformers/install --upgrade -r ./examples/requirements.txt --no-warn-script-location \

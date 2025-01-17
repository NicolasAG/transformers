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

try=1

for m1 in "np" # "spr" "sp" "lp" "lpr" "np"
do
  if [ $m1 == "sp" ]
  then
    mode="short"
    checkpoint="17280"  # facts (fs: # / ft: 17280) | amt (fs: # / ft: #)
  elif [ $m1 == "spr" ]
  then
    mode="short"
    checkpoint="17820"  # facts (fs: # / ft: 17820) | amt (fs: # / ft: #)
  elif [ $m1 == "lp" ]
  then
    mode="long"
    checkpoint="28080"  # facts (fs: # / ft: 28080) | amt (fs: # / ft: #)
  elif [ $m1 == "lpr" ]
  then
    mode="long"
    checkpoint="#####"  # facts (fs: # / ft: #) | amt (fs: # / ft: #)
  else
    mode="no"
    checkpoint="19980"  # facts (fs: # / ft: 14580) | amt (fs: 19980 / ft: 20520)
  fi
  for m2 in "amt" # "facts" "amt"
  do
    for i in 2 3 4 5 6 7 8 9 10
    do
      if [ $m1 == "np" ] || [ $i == 2 ] || [ $i == 3 ] || [ $i == 4 ]
      then
        ml=256
      else
        ml=512   # may raise IndexError due to GPT2 having only 1024 positional token embeddings
        # ml=1024  # will raise IndexError due to GPT2 having only 1024 positional token embeddings
      fi
      # STRAWMAN GPT2
      : '
      eai job submit \
          --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
          --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1:/clutrr \
          --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
          --cpu 1 \
          --mem 8 \
          --gpu 1 \
          --gpu-mem 6 \
          --name ""\
          --name "generate_test_1o${i}_${m1}_${m2}_hfgpt2_pure_try${try}" \
          --restartable \
          -- bash -c "cd hf_transformers/examples/text-generation \
                      && python run_generation.py \
                        --model_type=gpt2 \
                        --model_name_or_path=gpt2 \
                        --prompt=/clutrr/1.${i}_test/${mode}_proof_1.${i}_test_${m2}_ANON.txt \
                        --prefix=contexts/${m1}-${m2}-anon.txt \
                        --length=256 \
                        --temperature=0.7 \
                        --k=30 \
                        --p=0.9 \
                        --out_file=/clutrr/1.${i}_test/hf-gpt2-pure_${mode}-proof_${m2}.txt
          "
      '
      # FORWARD PROOFS & FINE-TUNED GPT
      : '
      eai job submit \
          --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
          --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1:/clutrr \
          --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
          --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
          --cpu 1 \
          --mem 8 \
          --gpu 1 \
          --gpu-mem 6 \
          --name "generate_test_1o${i}_${m1}_${m2}_hfgpt2_${checkpoint}_try${try}" \
          --restartable \
          -- bash -c "cd hf_transformers/examples/text-generation \
                      && python run_generation.py \
                        --model_type=gpt2 \
                        --model_name_or_path=/models/clutrr/1_${mode}-proof_${m2}_2_4_6/hf-gpt_anon/checkpoint-${checkpoint}_best/ \
                        --prompt=/clutrr/1.${i}_test/${mode}_proof_1.${i}_test_${m2}_ANON.txt \
                        --length=${ml} \
                        --temperature=0.7 \
                        --k=30 \
                        --p=0.9 \
                        --out_file=/clutrr/1.${i}_test/hf-gpt2_anon_${mode}-proof_${m2}.txt
          "
      '
      # BACKWARD PROOFS & FINE-TUNED GPT
      : '
      eai job submit \
          --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
          --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1_rev:/clutrr \
          --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
          --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
          --cpu 1 \
          --mem 8 \
          --gpu 1 \
          --gpu-mem 6 \
          --name ""\
          --name "generate_test_1o${i}_${m1}_${m2}_hfgpt2_${checkpoint}_try${try}" \
          --restartable \
          -- bash -c "cd hf_transformers/examples/text-generation \
                      && python run_generation.py \
                        --model_type=gpt2 \
                        --model_name_or_path=/models/clutrr/1_${mode}-proof-rev_${m2}_2_4_6/hf-gpt_anon/checkpoint-${checkpoint}_best/ \
                        --prompt=/clutrr/1.${i}_test/${mode}_proof_1.${i}_test_${m2}_ANON.txt \
                        --length=${ml} \
                        --temperature=0.7 \
                        --k=30 \
                        --p=0.9 \
                        --out_file=/clutrr/1.${i}_test/hf-gpt2_anon@${checkpoint}_${mode}-proof_${m2}.txt
          "
      '
      # FORWARD PROOFS & FROM-SCRATCH GPT
      eai job submit \
          --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
          --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1:/clutrr \
          --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
          --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
          --cpu 1 \
          --mem 8 \
          --gpu 1 \
          --gpu-mem 6 \
          --name "generate_test_1o${i}_${m1}_${m2}_hfgpt2fs_${checkpoint}_try${try}" \
          --restartable \
          -- bash -c "cd hf_transformers/examples/text-generation \
                      && python run_generation.py \
                        --model_type=gpt2 \
                        --model_name_or_path=/models/clutrr/1_${mode}-proof_${m2}_2_4_6/hf-gpt-fs_anon/checkpoint-${checkpoint}_best/ \
                        --prompt=/clutrr/1.${i}_test/${mode}_proof_1.${i}_test_${m2}_ANON.txt \
                        --length=${ml} \
                        --temperature=0.7 \
                        --k=30 \
                        --p=0.9 \
                        --out_file=/clutrr/1.${i}_test/hf-gpt2-fs_anon_${mode}-proof_${m2}.txt
          "
      done
  done
done
#eai job log -f --last

# && pip install . --no-warn-script-location \
# && pip install -r ./examples/requirements.txt --no-warn-script-location \
# && export PATH=$PATH:/tmp/.local/bin \

#--prefix=contexts/sp-facts-anon.txt \
#--prompt=test-1.2-facts-anon.txt \
#--prompt=/clutrr/1.2_test/short_proof_1.2_test_facts_ANON.txt \

#eai job log -f --last

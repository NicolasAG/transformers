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


eai job submit \
    --image registry.console.elementai.com/$ACCOUNT_ID/allennlp \
    --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1:/clutrr \
    --data $ORG_NAME.$ACCOUNT_NAME.data_clutrr1_rev:/clutrr_rev \
    --data $ORG_NAME.$ACCOUNT_NAME.$eai_code:/hf_transformers \
    --data $ORG_NAME.$ACCOUNT_NAME.models_gpt2:/models \
    --cpu 1 \
    --mem 8 \
    --non-preemptable \
    -- bash -c "while true; do sleep 60; done;"
    #-- bash -c "cd hf_transformers && chmod +x *.sh && ./make_training_files.sh"
    #-- bash -c "cd hf_transformers && chmod +x *.sh && ./make_prefixes.sh"
eai job exec --last -- bash
#eai job log -f --last

#--gpu 1 \
#--gpu-mem 6 \


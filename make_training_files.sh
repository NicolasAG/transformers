#!/usr/bin/env bash

context_folder="./data"

for m1 in "short" "long" "no"
do
  if [ $m1 == "short" ]
  then
    afile=${context_folder}/sp
  elif [ $m1 == "long" ]
  then
    afile=${context_folder}/lp
  else
    afile=${context_folder}/np
  fi
  for m2 in "amt" # "facts" "amt"
  do
    cat /clutrr/1.2345678910_train/${m1}_proof_1.2_train_${m2}_anon.txt.4000 > ${afile}-${m2}-anon[train].txt
    cat /clutrr/1.2345678910_train/${m1}_proof_1.4_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[train].txt
    cat /clutrr/1.2345678910_train/${m1}_proof_1.6_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[train].txt
    echo "number of training lines for ${m1}-proofs / ${m2}:"
    wc -l ${afile}-${m2}-anon[train].txt

    cat /clutrr/1.2345678910_valid/${m1}_proof_1.2_valid_${m2}_anon.txt.4000 > ${afile}-${m2}-anon[valid].txt
    cat /clutrr/1.2345678910_valid/${m1}_proof_1.4_valid_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[valid].txt
    cat /clutrr/1.2345678910_valid/${m1}_proof_1.6_valid_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[valid].txt
    echo "number of validation lines for ${m1}-proofs / ${m2}:"
    wc -l ${afile}-${m2}-anon[valid].txt
  done
done

for m1 in "short" "long"
do
  if [ $m1 == "short" ]
  then
    afile=${context_folder}/spr
  else
    afile=${context_folder}/lpr
  fi
  for m2 in "amt" # "facts" "amt"
  do
    cat /clutrr_rev/1.2345678910_train/${m1}_proof_1.2_train_${m2}_anon.txt.4000 > ${afile}-${m2}-anon[train].txt
    cat /clutrr_rev/1.2345678910_train/${m1}_proof_1.4_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[train].txt
    cat /clutrr_rev/1.2345678910_train/${m1}_proof_1.6_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[train].txt
    echo "number of training lines for ${m1}-proofs-reversed / ${m2}:"
    wc -l ${afile}-${m2}-anon[train].txt

    cat /clutrr_rev/1.2345678910_valid/${m1}_proof_1.2_valid_${m2}_anon.txt.4000 > ${afile}-${m2}-anon[valid].txt
    cat /clutrr_rev/1.2345678910_valid/${m1}_proof_1.4_valid_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[valid].txt
    cat /clutrr_rev/1.2345678910_valid/${m1}_proof_1.6_valid_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon[valid].txt
    echo "number of validation lines for ${m1}-proofs-reversed / ${m2}:"
    wc -l ${afile}-${m2}-anon[valid].txt
  done
done

#!/usr/bin/env bash

context_folder="./examples/text-generation/contexts"

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
  for m2 in "facts" "amt"
  do
    head -1 /clutrr/1.2345678910_train/${m1}_proof_1.2_train_${m2}_anon.txt.4000 > ${afile}-${m2}-anon.txt
    head -1 /clutrr/1.2345678910_train/${m1}_proof_1.4_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon.txt
    head -1 /clutrr/1.2345678910_train/${m1}_proof_1.6_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon.txt
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
  for m2 in "facts" "amt"
  do
    head -1 /clutrr_rev/1.2345678910_train/${m1}_proof_1.2_train_${m2}_anon.txt.4000 > ${afile}-${m2}-anon.txt
    head -1 /clutrr_rev/1.2345678910_train/${m1}_proof_1.4_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon.txt
    head -1 /clutrr_rev/1.2345678910_train/${m1}_proof_1.6_train_${m2}_anon.txt.4000 >> ${afile}-${m2}-anon.txt
  done
done

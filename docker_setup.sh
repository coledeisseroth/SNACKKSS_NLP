#!/bin/bash
set -e

cd /app/metadata
bash BUILD.sh

cd /app/study
bash BUILD.sh

cd /app/sample
bash BUILD.sh

cd /app/target
bash BUILD.sh

cd /app/control
bash BUILD.sh

cd /app

mkdir /app/output
for stage in study sample target control; do
for pert in gene drug; do
mv /app/$stage/$pert/final_model /app/output/${pert}_${stage}_model
done
done

for stage in study sample target control; do
for pert in gene drug; do
cat /app/$stage/$pert/best_combination.txt | awk '{print "'$pert'\t'$stage'\t" $0}'
done
done > /app/output/optima.txt


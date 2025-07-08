#!/bin/bash
#Note: In a perfect world, simply running this bash script should be sufficient. However, more likely than not, your computer will crash in the middle of this whole process, and you'll want to pick it up from where you left off. So if you are interested in replicating this pipeline, we recommend going through the BUILD.sh scripts one by one, command by command.
cd metadata
bash BUILD.sh
cd ..

cd study
bash BUILD.sh
cd ..

cd sample
bash BUILD.sh
cd ..

cd target
bash BUILD.sh
cd ..

cd control
bash BUILD.sh
cd ..

mkdir output
for stage in study sample target control; do
for pert in gene drug; do
mv $stage/$pert/final_model output/${pert}_${stage}_model
done
done

for stage in study sample target control; do
for pert in gene drug; do
cat $stage/$pert/best_combination.txt | awk '{print "'$pert'\t'$stage'\t" $0}'
done
done > output/optima.txt


for pert in gene drug; do mkdir $pert; mkdir $pert/SNACKKSS_MC $pert/CREEDS; done

cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "KO" || $2 == "KD"' | cut -f4- | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $1); print $2 "\t" $1}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -u | sed 's/;/\t/g' | sed 's/&/\t/g' | sort -k1,1 | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $1 "\t" $i}}' | sort -u | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; terms = ""} {if(cur != "" && cur != $1){print cur "\t" terms; terms = ""} cur = $1; terms = terms ";" $2} END {print cur "\t" terms}' | sed 's/\t;*/\t/g' | sed 's/;/:GENE;/g' | awk '{print $0 ":GENE"}' > gene/SNACKKSS_MC/target_names.txt
cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "D"' | cut -f4- | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $1); print $2 "\t" $1}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -u | sed 's/;/\t/g' | sed 's/&/\t/g' | sort -k1,1 | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $1 "\t" $i}}' | sort -u | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; terms = ""} {if(cur != "" && cur != $1){print cur "\t" terms; terms = ""} cur = $1; terms = terms ";" $2} END {print cur "\t" terms}' | sed 's/\t;*/\t/g' | sed 's/;/:CHEM;/g' | awk '{print $0 ":CHEM"}' > drug/SNACKKSS_MC/target_names.txt
cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f7,8,10,11 | sort -t$'\t' -k4,4 | join -t$'\t' -1 4 -2 1 - <(cat ../corpora/CREEDS/fixed_kokd_terms.txt | sort -u) | cut -f2- | awk 'BEGIN {FS = "\t"} {gsub(";.*", "", $1); gsub(";.*", "", $2); gsub("\\|", "\t", $3); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){print $i "\t" $1; print $i "\t" $2}}' | sort -k1,1 | join -t$'\t' - <(cat ../sample/gene/CREEDS/labels.txt | awk '$2 == 1' | cut -f1 | sort -u) | sort -u | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""} $2 != "" {if($1 != cur && cur != ""){print cur "\t" items; items = ""} cur = $1; items = items "\t" $2} END {pritn cur "\t" items}' | cut -f1,3- | sort -k1,1 | join -t$'\t' <(cat ../metadata/CREEDS/sample_info_protocols.txt | cut -f2- | sort -k1,1) - | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++) {items = ""; if(index($2, $i) > 0){items = items ";" $i ":GENE"}} if(items != ""){print $1 "\t" items}}' | sed 's/\t;*/\t/g' | sort -u > gene/CREEDS/target_names.txt
cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f5,9 | awk 'BEGIN {FS = "\t"} {gsub("\\|", "\t", $2); print $1 "\t" $2}' | awk 'BEGIN {FS = "\t"} {for(i=2; i <= NF; i++){print $i "\t" $1}}' | sort -k1,1 | join -t$'\t' - <(cat ../sample/drug/CREEDS/labels.txt | awk '$2 == 1' | cut -f1 | sort -u) | sort -u | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""} $2 != "" {if($1 != cur && cur != ""){print cur "\t" items; items = ""} cur = $1; items = items "\t" $2} END {pritn cur "\t" items}' | cut -f1,3- | sort -k1,1 | join -t$'\t' <(cat ../metadata/CREEDS/sample_info_protocols.txt | cut -f2- | sort -k1,1) - | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++) {items = ""; if(index($2, $i) > 0){items = items ";" $i ":CHEM"}} if(items != ""){print $1 "\t" items}}' | sed 's/\t;*/\t/g' | sort -u > drug/CREEDS/target_names.txt

#Train and evaluate each model
for pert in gene drug; do
for db in CREEDS SNACKKSS_MC; do
for model in distilbert biobert biomedbert; do
if [ $(echo $model | grep distilbert | wc -l) -gt 0 ]; then hfmodel='distilbert/distilbert-base-uncased'
elif [ $(echo $model | grep biobert | wc -l) -gt 0 ]; then hfmodel='dmis-lab/biobert-v1.1'
else hfmodel='microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext'
fi
mkdir $pert/$db/$model
bash src/target_classification.sh $pert/$db/$model $pert/$db/target_names.txt ../metadata/$db/sample_info_protocols.txt $hfmodel ../metadata/$db/split ../raw/target_label_list.txt
done
done
done

for pert in gene drug; do
mkdir $pert/combo
for model in distilbert biobert biomedbert; do
mkdir $pert/combo/$model
bash src/compare_token_classifiers.sh $pert/combo/$model $pert/SNACKKSS_MC/$model/models $pert/CREEDS/$model/models/ $pert/SNACKKSS_MC/$model/training_datasets $pert/CREEDS/$model/training_datasets/ $pert/SNACKKSS_MC/$model/name_labels_test $pert/CREEDS/$model/name_labels_test
done
done

#Do a formal comparison
for pert in gene drug; do
if [ $(echo $pert | grep gene | wc -l) -gt 0 ]; then label=GENE
else label=CHEM; fi
(echo $'\tSNACKKSS_MC true positive\tSNACKKSS_MC false positive\tSNACKKSS_MC false negative\tCREEDS true positive\tCREEDS false positive\tCREEDS false negative'
for modelname in DistilBERT BioBERT BioMedBERT; do
model=$(echo $modelname | tr '[:upper:]' '[:lower:]')
for train in 1 2 12 21; do
comboname=$(echo $train | sed 's/12/SNACKKSS_MC+CREEDS/g' | sed 's/21/CREEDS+SNACKKSS_MC/g' | sed 's/1/SNACKKSS_MC/g' | sed 's/2/CREEDS/g')
for test in 1 2; do
if [ $(echo test | grep 1 | wc -l) -gt 0 ]; then db=SNACKKSS_MC; else db=CREEDS; fi
cat $pert/$db/$model/position_labels_test/* | cut -f-2 | sed 's/;/\t/g' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++) {print $1 "\t" $i}}' | grep ":"$label | cut -d: -f1 | awk '$2 != ""' | sort -u | comm - <(cat $pert/combo/$model/predictions${train}.${test}_merged/* | cut -f-2 | sed 's/;/\t/g' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++) {print $1 "\t" $i}}' | grep ":"$label | cut -d: -f1 | awk '$2 != ""' | sort -u) | awk 'BEGIN {FS = "\t"; tp = 0; fp = 0; fn = 0} {if($2 == ""){tp++} else if($1 == ""){fp++} else{fn++}} END {precision = tp / (tp + fp + 1); recall = tp / (tp + fn + 1); print tp "\t" fp "\t" fn}'
done | paste -sd$'\t' | awk '{print "'$modelname'+'$comboname'\t" $0}'
done
done) > $pert/full_comparison.txt
done

#Get the best model, and do the final train.
for pert in gene drug; do
combo=$(cat $pert/full_comparison.txt | cut -f-4 | grep BERT | awk 'BEGIN {FS = "\t"} {precision = $2/($2+$3+1); recall = $2 /($2+$4+1); f1 = 3 * precision * recall / (precision+recall+1); print $1 "\t" f1}' | sort -k2,2gr -k1,1 | head -1 | cut -f1 | sed 's/+/\t/g' | awk 'BEGIN {FS = "\t"} {model = $1; if(model == "DistilBERT"){hfmodel = "distilbert/distilbert-base-uncased"} else if(model == "BioBERT"){hfmodel = "dmis-lab/biobert-v1.1"} else if(model == "BioMedBERT"){hfmodel = "microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext"} print hfmodel; for(i=2; i <= NF; i++){print "'$pert'/" $i "/" tolower(model) "/final_training_dataset.json"}}' | paste -sd$'#')
cat $(echo $combo | cut -d'#' -f2- | sed 's/#/ /g') > $pert/final_training_dataset.json
python3 src/target_finetune.py $pert/final_training_dataset.json $pert/final_model $(echo $combo | cut -d'#' -f1)
done



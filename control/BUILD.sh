#!/bin/bash
rm -rf gene drug
for pert in gene drug; do mkdir $pert; mkdir $pert/SNACKKSS_MC $pert/CREEDS; done

#Get the pairs of samples where one has exactly one fewer perturbation of a given type than the other. If this isn't the case, then you know neither is an appropriate control to the other (except in rare cases where, for instance, one is evaluating heterozygous vs. full knockouts--but we do not consider those cases at the moment).
#SNACKKSS_MC gene
cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "KO" || $2 == "KD"' | cut -f4- | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $1); print $2 "\t" $1}' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $i "\t" $1}}' | sed 's/&/\t/g' | awk 'BEGIN {FS = "\t"} {for(i=2; i<=NF; i++){print $1 "\t" $i}}' | sort -u | cut -d';' -f1 | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; names = ""} {if(cur != "" && cur != $1){print cur "\t" names; names = ""} cur = $1; names = names ";" $2} END {print cur "\t" names}' | sed 's/\t;/\t/g' > gene/SNACKKSS_MC/sample_targets_wide.txt
(cat gene/SNACKKSS_MC/sample_targets_wide.txt | grep -v ';' | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "KO" || $2 == "KD"' | cut -f4 | sed 's/;/\n/g' | sort -u | grep -vwf - <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2) | sort -k1,1); cat gene/SNACKKSS_MC/sample_targets_wide.txt | grep ';' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat gene/SNACKKSS_MC/sample_targets_wide.txt | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $4 "\t" $3 "\t" $5}' | sort -u | awk 'BEGIN {FS = "\t"} $2 != $3 {x = $3; gsub(";", "\t", x); print $1 "\t" $2 "\t" $3 "\t;" $2 ";\t" x}' | awk 'BEGIN {FS = "\t"} {for(i=5; i <= NF; i++){if(index($4, ";" $i ";") == 0){next} else{gsub(";" $i ";", ";", $4)}} if($4 != ";" && index(substr($4, 2, length($4) - 2), ";") == 0){print $1}}' | sed 's/_/\t/g') | sort -u | sort -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../metadata/SNACKKSS_MC/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u) | sort -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../metadata/SNACKKSS_MC/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u) | awk '{print $3 "\t" $1 "\t" $2}' > gene/SNACKKSS_MC/minusone_pairs.txt
cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "KO" || $2 == "KD"' | cut -f1,3,4 | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $3); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $2); for(i=3; i <= NF; i++) {print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){print $1 "\t" $2 "\t" $i}}' > gene/SNACKKSS_MC/control_perturb_pairs.txt
#SNACKKSS_MC drug
cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "D"' | cut -f4- | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $1); print $2 "\t" $1}' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $i "\t" $1}}' | sed 's/&/\t/g' | awk 'BEGIN {FS = "\t"} {for(i=2; i<=NF; i++){print $1 "\t" $i}}' | sort -u | cut -d';' -f1 | sort -k1,1 | awk 'BEGIN {FS = "\t"; cur = ""; names = ""} {if(cur != "" && cur != $1){print cur "\t" names; names = ""} cur = $1; names = names ";" $2} END {print cur "\t" names}' | sed 's/\t;/\t/g' > drug/SNACKKSS_MC/sample_targets_wide.txt
(cat drug/SNACKKSS_MC/sample_targets_wide.txt | grep -v ';' | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "D"' | cut -f4 | sed 's/;/\n/g' | sort -u | grep -vwf - <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2) | sort -k1,1); cat drug/SNACKKSS_MC/sample_targets_wide.txt | grep ';' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat drug/SNACKKSS_MC/sample_targets_wide.txt | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/SNACKKSS_MC/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $4 "\t" $3 "\t" $5}' | sort -u | awk 'BEGIN {FS = "\t"} $2 != $3 {x = $3; gsub(";", "\t", x); print $1 "\t" $2 "\t" $3 "\t;" $2 ";\t" x}' | awk 'BEGIN {FS = "\t"} {for(i=5; i <= NF; i++){if(index($4, ";" $i ";") == 0){next} else{gsub(";" $i ";", ";", $4)}} if($4 != ";" && index(substr($4, 2, length($4) - 2), ";") == 0){print $1}}' | sed 's/_/\t/g') | sort -u | sort -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../metadata/SNACKKSS_MC/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u) | sort -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../metadata/SNACKKSS_MC/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u) | awk '{print $3 "\t" $1 "\t" $2}' > drug/SNACKKSS_MC/minusone_pairs.txt
cat ../metadata/SNACKKSS_MC/perturbations_cleaned.txt | awk '$2 == "D"' | cut -f1,3,4 | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $3); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {gsub(";", "\t", $2); for(i=3; i <= NF; i++) {print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){print $1 "\t" $2 "\t" $i}}' > drug/SNACKKSS_MC/control_perturb_pairs.txt
#CREEDS gene
cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f7,10,11 | sort -t$'\t' -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../corpora/CREEDS/fixed_kokd_terms.txt | sort -u) | cut -f2- | grep GSM | sed 's/|/\t/g' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $i "\t" $1}}' | sort -u | sort -k1,1 | join -t$'\t' - <(cat ../target/gene/CREEDS/target_names.txt | cut -f1 | sort -u) | awk 'BEGIN {FS = "\t"; cur = ""; names = ""} {if(cur != "" && cur != $1){print cur "\t" names; names = ""} cur = $1; names = names ";" $2} END {print cur "\t" names}' | sed 's/\t;/\t/g' > gene/CREEDS/sample_targets_wide.txt
(cat gene/CREEDS/sample_targets_wide.txt | grep -v ';' | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f10 | grep GSM | sed 's/|/\n/g' | sort -u | grep -vwf - <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2) | sort -k1,1); cat gene/CREEDS/sample_targets_wide.txt | grep ';' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat gene/CREEDS/sample_targets_wide.txt | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $4 "\t" $3 "\t" $5}' | sort -u | awk 'BEGIN {FS = "\t"} $2 != $3 {x = $3; gsub(";", "\t", x); print $1 "\t" $2 "\t" $3 "\t;" $2 ";\t" x}' | awk 'BEGIN {FS = "\t"} {for(i=5; i <= NF; i++){if(index($4, ";" $i ";") == 0){next} else{gsub(";" $i ";", ";", $4)}} if($4 != ";" && index(substr($4, 2, length($4) - 2), ";") == 0){print $1}}' | sed 's/_/\t/g') | sort -u > gene/CREEDS/minusone_pairs.txt
cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f4,6,10,11 | sort -t$'\t' -k4,4 | join -t$'\t' -1 4 -2 1 - <(cat ../corpora/CREEDS/fixed_kokd_terms.txt | sort -u) | cut -f2- | grep GSE | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../study/gene/CREEDS/labels.txt | awk '$2 == 1' | cut -f1 | sort -u) | awk 'BEGIN {FS = "\t"} {gsub("\\|", "\t", $3); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {gsub("\\|", "\t", $2); for(i=3; i <= NF; i++) {print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){print $1 "\t" $2 "\t" $i}}' | sort -u | comm -12 - <(cat gene/CREEDS/minusone_pairs.txt | sort -u) > gene/CREEDS/control_perturb_pairs.txt
#CREEDS drug
cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f5,9 | grep GSM | sed 's/|/\t/g' | awk 'BEGIN {FS = "\t"} {for(i = 2; i <= NF; i++){print $i "\t" $1}}' | sort -u | sort -k1,1 | join -t$'\t' - <(cat ../target/drug/CREEDS/target_names.txt | cut -f1 | sort -u) | awk 'BEGIN {FS = "\t"; cur = ""; names = ""} {if(cur != "" && cur != $1){print cur "\t" names; names = ""} cur = $1; names = names ";" $2} END {print cur "\t" names}' | sed 's/\t;/\t/g' > drug/CREEDS/sample_targets_wide.txt
(cat drug/CREEDS/sample_targets_wide.txt | grep -v ';' | cut -f1 | sort -u | join -t$'\t' -1 1 -2 2 - <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f9 | grep GSM | sed 's/|/\n/g' | sort -u | grep -vwf - <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2) | sort -k1,1); cat drug/CREEDS/sample_targets_wide.txt | grep ';' | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2 | join -t$'\t' -1 2 -2 2 - <(cat drug/CREEDS/sample_targets_wide.txt | sort -k1,1 | join -t$'\t' -1 2 -2 1 <(cat ../metadata/CREEDS/sample_info.txt | cut -f-2 | sort -k2,2) - | sort -k2,2) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $4 "\t" $3 "\t" $5}' | sort -u | awk 'BEGIN {FS = "\t"} $2 != $3 {x = $3; gsub(";", "\t", x); print $1 "\t" $2 "\t" $3 "\t;" $2 ";\t" x}' | awk 'BEGIN {FS = "\t"} {for(i=5; i <= NF; i++){if(index($4, ";" $i ";") == 0){next} else{gsub(";" $i ";", ";", $4)}} if($4 != ";" && index(substr($4, 2, length($4) - 2), ";") == 0){print $1}}' | sed 's/_/\t/g') | sort -u > drug/CREEDS/minusone_pairs.txt
cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f3,7,9 | grep GSE | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../study/drug/CREEDS/labels.txt | awk '$2 == 1' | cut -f1 | sort -u) | awk 'BEGIN {FS = "\t"} {gsub("\\|", "\t", $3); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {gsub("\\|", "\t", $2); for(i=3; i <= NF; i++) {print $1 "\t" $i "\t" $2}}' | awk 'BEGIN {FS = "\t"} {for(i=3; i <= NF; i++){print $1 "\t" $2 "\t" $i}}' | sort -u | comm -12 - <(cat drug/CREEDS/minusone_pairs.txt | sort -u) > drug/CREEDS/control_perturb_pairs.txt

#Get paired sample descriptions. Also, remove studies with exorbitant numbers of sample pairs (>10,000 pairs).
for pert in gene drug; do for db in SNACKKSS_MC CREEDS; do
cat $pert/$db/minusone_pairs.txt | grep -vwf <(cat $pert/$db/minusone_pairs.txt | cut -f1 | sort | uniq -c | awk '$1 > 10000 {print $2}' | sort -u) | sort -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../metadata/$db/sample_info.txt | cut -f2- | sort -k1,1) | sort -k3,3 | join -t$'\t' -1 3 -2 1 - <(cat ../metadata/$db/sample_info.txt | cut -f2- | sort -k1,1) | awk 'BEGIN {FS = "\t"} {print $3 "\t" $2 "\t" $4 "\t" $1 "\t" $5}' | sort -u > $pert/$db/sample_pairs.txt
done; done

#List the sample pairs where we know one is NOT a control to the other
for pert in gene drug; do for db in SNACKKSS_MC CREEDS; do
cat $pert/$db/control_perturb_pairs.txt | sort -u | comm -13 - <(cat $pert/$db/minusone_pairs.txt | sort -u) > $pert/$db/unrelated_pairs.txt
done; done

#Align the descriptions and concatenate the bits that were exclusive to the potential control sample
for pert in gene drug; do for db in SNACKKSS_MC CREEDS; do
python3 src/align_sample_descriptions.py $pert/$db/sample_pairs.txt | cut -f1,2,4,6 > $pert/$db/alignments.txt
done; done

#Join the alignments with the control/unrelated labels
for pert in gene drug; do for db in SNACKKSS_MC CREEDS; do
(cat $pert/$db/control_perturb_pairs.txt | sed 's/\t/_/g' | awk '{print $0 "\t1"}'; cat $pert/$db/unrelated_pairs.txt | sed 's/\t/_/g' | awk '{print $0 "\t0"}') | sort -k1,1 | join -t$'\t' - <(cat $pert/$db/alignments.txt | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $3 "\t" $4}' | sort -k1,1) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3}' > $pert/$db/labeled_pairs.txt
done; done

for pert in gene drug; do
for db in CREEDS SNACKKSS_MC; do
for model in distilbert biobert biomedbert; do
if [ $(echo $model | grep distilbert | wc -l) -gt 0 ]; then hfmodel='distilbert/distilbert-base-uncased'
elif [ $(echo $model | grep biobert | wc -l) -gt 0 ]; then hfmodel='dmis-lab/biobert-v1.1'
else hfmodel='microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext'
fi
mkdir $pert/$db/$model
bash src/control_classification.sh $pert/$db/$model $pert/$db/labeled_pairs.txt $hfmodel ../metadata/$db/split
done; done; done

#Test the performance from training on one dataset and then the other
for pert in gene drug; do
mkdir $pert/combo
for model in distilbert biobert biomedbert; do
mkdir $pert/combo/$model
bash ../src/compare_text_classifiers.sh $pert/$combo/$model $pert/SNACKKSS_MC/$model/models $pert/CREEDS/$model/models/ $pert/SNACKKSS_MC/$model/training_datasets $pert/CREEDS/$model/training_datasets/ $pert/SNACKKSS_MC/$model/testing_datasets $pert/CREEDS/$model/testing_datasets
done
done

#Do a formal comparison. Note that these precision/recall values are weighted by the number of other samples a given perturbed sample is compared to.
for pert in gene drug; do
(echo $'\tSNACKKSS_MC true positive\tSNACKKSS_MC false positive\tSNACKKSS_MC false negative\tCREEDS true positive\tCREEDS false positive\tCREEDS false negative'
for modelname in DistilBERT BioBERT BioMedBERT; do
model=$(echo $modelname | tr '[:upper:]' '[:lower:]')
for train in 1 2 12 21; do
comboname=$(echo $train | sed 's/12/SNACKKSS_MC+CREEDS/g' | sed 's/21/CREEDS+SNACKKSS_MC/g' | sed 's/1/SNACKKSS_MC/g' | sed 's/2/CREEDS/g')
for test in 1 2; do cat $pert/combo/$model/predictions${train}.${test}/* | cut -f-2 | awk 'BEGIN {FS = "_"} {print $2 "\t" $0}' | sort -k1,1 | join -t$'\t' - <(cat $pert/combo/$model/predictions${train}.${test}/* | cut -d_ -f2 | sort | uniq -c | awk '{print $2 "\t" 1 / $1}' | sort -u | sort -k1,1) | sed 's/_/\t/g' | sed 's/POSITIVE/1/g' | sed 's/NEGATIVE/0/g' | awk 'BEGIN {FS = "\t"} {if($5 == 1){$5 = 1} else{$5 = 0} print $5 "\t" $6 "\t" $7}' | awk 'BEGIN {FS = "\t"; tp = 0; fp = 0; fn = 0} {if($1 == 1 && $2 == 1){tp += $3} else if($1 == 1){fn += $3} else if($2 == 1){fp += $3}} END {print tp "\t" fp "\t" fn}'; done | paste -sd$'\t' | awk '{print "'$modelname'+'$comboname'\t" $0}'; done
done) > $pert/full_comparison.txt
done

#Get the best model, and do the final train.
for pert in gene drug; do
cat $pert/full_comparison.txt | cut -f-4 | grep BERT | awk 'BEGIN {FS = "\t"} {precision = $2/($2+$3+1); recall = $2 /($2+$4+1); f1 = 3 * precision * recall / (precision+recall+1); print $1 "\t" f1}' | sort -k2,2gr -k1,1 | head -1 | cut -f1 > $pert/best_combination.txt
combo=$(cat $pert/best_combination.txt | sed 's/+/\t/g' | awk 'BEGIN {FS = "\t"} {model = $1; if(model == "DistilBERT"){hfmodel = "distilbert/distilbert-base-uncased"} else if(model == "BioBERT"){hfmodel = "dmis-lab/biobert-v1.1"} else if(model == "BioMedBERT"){hfmodel = "microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext"} print hfmodel; for(i=2; i <= NF; i++){print "'$pert'/" $i "/" tolower(model) "/final_training_dataset.json"}}' | paste -sd$'#')
cat $(echo $combo | cut -d'#' -f2- | sed 's/#/ /g') > $pert/final_training_dataset.json
python3 ../src/text_classification_finetune.py $pert/final_training_dataset.json $pert/final_model $(echo $combo | cut -d'#' -f1)
done



for pert in gene drug; do mkdir $pert; mkdir $pert/SNACKKSS_MC $pert/CREEDS; done

#Studies either do or do not qualify for gene/drug perturbation. First, get those binary labels. Each dataset needs separate handling.
(cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2,4 | awk 'BEGIN {FS = "\t"} $2 == "KO" || $2 == "KD"' | cut -f1 | sort -u | awk '{print $1 "\t1"}'; cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2 | sort -u | comm -23 - <(cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2,4 | awk 'BEGIN {FS = "\t"} $2 == "KO" || $2 == "KD"' | cut -f1 | sort -u) | awk '{print $1 "\t0"}') | grep GSE | sort -u > gene/SNACKKSS_MC/labels.txt
(cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2,4 | awk 'BEGIN {FS = "\t"} $2 == "D"' | cut -f1 | sort -u | awk '{print $1 "\t1"}'; cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2 | sort -u | comm -23 - <(cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2,4 | awk 'BEGIN {FS = "\t"} $2 == "D"' | cut -f1 | sort -u) | awk '{print $1 "\t0"}') | grep GSE | sort -u > drug/SNACKKSS_MC/labels.txt
(cat ../corpora/CREEDS/single_gene_fixed.txt | awk 'NR > 1' | cut -f6,11 | sort -t$'\t' -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../corpora/CREEDS/fixed_kokd_terms.txt) | cut -f2 | sort -u | awk '{print $1 "\t1"}'; (cat ../corpora/CREEDS/single_gene_fixed.txt | awk 'NR > 1' | cut -f6; cat ../corpora/CREEDS/single_drug_fixed.txt | awk 'NR > 1' | cut -f7) | sort -u | comm -23 - <(cat ../corpora/CREEDS/single_gene_fixed.txt | awk 'NR > 1' | cut -f6,11 | sort -t$'\t' -k2,2 | join -t$'\t' -1 2 -2 1 - <(cat ../corpora/CREEDS/fixed_kokd_terms.txt) | cut -f2 | sort -u) | awk '{print $1 "\t0"}') | sort -u > gene/CREEDS/labels.txt
(cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f7 | awk 'NR > 1 {print $0 "\t1"}' | sort -u; cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f7 | awk 'NR > 1' | sort -u | comm -13 - <(cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f6 | awk 'NR > 1' | sort -u) | awk '{print $1 "\t0"}') | sort -u > drug/CREEDS/labels.txt

#Train and evaluate each model
for pert in gene drug; do
for db in CREEDS SNACKKSS_MC; do
for model in distilbert biobert biomedbert; do
if [ $(echo $model | grep distilbert | wc -l) -gt 0 ]; then hfmodel='distilbert/distilbert-base-uncased'
elif [ $(echo $model | grep biobert | wc -l) -gt 0 ]; then hfmodel='dmis-lab/biobert-v1.1'
else hfmodel='microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext'
fi
mkdir $pert/$db/$model
bash src/study_classification.sh $pert/$db/$model $pert/$db/labels.txt ../metadata/$db/study_info.txt $hfmodel ../metadata/$db/split
done
done
done

#Test the performance from training on one dataset and then the other
for pert in gene drug; do
mkdir $pert/combo
for model in distilbert biobert biomedbert; do
mkdir $pert/combo/$model
bash ../src/compare_text_classifiers.sh $pert/combo/$model $pert/SNACKKSS_MC/$model/models $pert/CREEDS/$model/models/ $pert/SNACKKSS_MC/$model/training_datasets $pert/CREEDS/$model/training_datasets/ $pert/SNACKKSS_MC/$model/testing_datasets $pert/CREEDS/$model/testing_datasets
done
done

#Do a formal comparison. This is how we get Figure 1 and Supplemental Figure 2.
for pert in gene drug; do
(echo $'\tSNACKKSS_MC true positive\tSNACKKSS_MC false positive\tSNACKKSS_MC false negative\tCREEDS true positive\tCREEDS false positive\tCREEDS false negative'
for modelname in DistilBERT BioBERT BioMedBERT; do
model=$(echo $modelname | tr '[:upper:]' '[:lower:]')
for train in 1 2 12 21; do
comboname=$(echo $train | sed 's/12/SNACKKSS_MC+CREEDS/g' | sed 's/21/CREEDS+SNACKKSS_MC/g' | sed 's/1/SNACKKSS_MC/g' | sed 's/2/CREEDS/g')
for test in 1 2; do cat $pert/combo/$model/predictions${train}.${test}/* | awk 'BEGIN {FS = "\t"} {gsub("_", "\t", $1); print $1 "\t" $2 "\t" $3}' | cut -f1,3,4 | sort -k3,3r | sort -k1,1 -u | cut -f2- | awk 'BEGIN {FS = "\t"; tp = 0; fp = 0; fn = 0} {if($1 == 0 && $2 == "POSITIVE"){fp++} else if($1 != 0 && $2 == "NEGATIVE"){fn++} else if($1 != 0 && $2 == "POSITIVE"){tp++}} END {print tp "\t" fp "\t" fn}'; done | paste -sd$'\t' | awk '{print "'$modelname'+'$comboname'\t" $0}'; done
done) > $pert/full_comparison.txt
done

#Get the best model, and do the final train.
#Side note: We add 1 to all denominators to prevent division by zero. F1 scores use a coefficient of 3 instead of 2 to keep it normalized from 0 to 1.
for pert in gene drug; do
cat $pert/full_comparison.txt | cut -f-4 | grep BERT | awk 'BEGIN {FS = "\t"} {precision = $2/($2+$3+1); recall = $2 /($2+$4+1); f1 = 3 * precision * recall / (precision+recall+1); print $1 "\t" f1}' | sort -k2,2gr -k1,1 | head -1 | cut -f1 > $pert/best_combination.txt
combo=$(cat $pert/best_combination.txt | sed 's/+/\t/g' | awk 'BEGIN {FS = "\t"} {model = $1; if(model == "DistilBERT"){hfmodel = "distilbert/distilbert-base-uncased"} else if(model == "BioBERT"){hfmodel = "dmis-lab/biobert-v1.1"} else if(model == "BioMedBERT"){hfmodel = "microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext"} print hfmodel; for(i=2; i <= NF; i++){print "'$pert'/" $i "/" tolower(model) "/final_training_dataset.json"}}' | paste -sd$'#')
cat $(echo $combo | cut -d'#' -f2- | sed 's/#/ /g') > $pert/final_training_dataset.json
python3 ../src/text_classification_finetune.py $pert/final_training_dataset.json $pert/final_model $(echo $combo | cut -d'#' -f1)
done



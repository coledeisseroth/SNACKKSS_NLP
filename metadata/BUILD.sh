#Collate the study IDs whose soft files we need to download
mkdir CREEDS SNACKKSS_MC
(cat ../corpora/CREEDS/single_gene_fixed.txt | cut -f6; cat ../corpora/CREEDS/single_drug_fixed.txt | cut -f7) | grep GSE | sort -u > CREEDS/studies.txt
cat ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt | cut -f2 | grep GSE | sort -u > SNACKKSS_MC/studies.txt

#Get the links to those soft files
for db in CREEDS SNACKKSS_MC; do
for gse in $(cat $db/studies.txt); do subfolder=$(echo $gse | awk '{if(length($1) < 7){print "GSEnnn"} else{print substr($1, 0, length($1) - 3) "nnn"}}'); echo https://ftp.ncbi.nlm.nih.gov/geo/series/$subfolder/$gse/soft/${gse}_family.soft.gz; done > $db/soft_file_links.txt
done

#Download the soft files. Skips the ones that you already have.
for db in CREEDS SNACKKSS_MC; do
mkdir $db/soft_files
cd $db/soft_files
for link in $(cat ../soft_file_links.txt | grep -vwf <(ls | cut -d_ -f1 | sort -u)); do
wget $link
sleep 1
done
cd ../..
done

#Gather the information needed for study classification
for db in CREEDS SNACKKSS_MC; do
for file in $(ls $db/soft_files); do zcat $db/soft_files/$file | sed 's/\r//g' | grep -wf ../corpora/lexica/series_useful_fields.txt | sort -u | cut -d' ' -f3- | paste -sd$'\t' | sed 's/\t/. /g' | sed 's/\.\. /. /g' | awk '{print "'$(echo $file | cut -d_ -f1)'\t" $0}'; done | sed 's/"//g' | sed 's/\\//g' | sort -u > $db/study_info.txt
done

#Gather the information needed for sample and control classification
for db in CREEDS SNACKKSS_MC; do
for study in $(ls $db/soft_files/ | cut -d_ -f1 | grep GSE | sort -u); do zcat $db/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; cat ../corpora/lexica/sample_useful_fields.txt | grep -v protocol) | sed 's/\^SAMPLE = /. . \^SAMPLE = /g' | cut -d' ' -f3- | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | sort -u > $db/sample_info.txt
done

#Gather the information needed for target classification (i.e. include the protocols)
for db in CREEDS SNACKKSS_MC; do
for study in $(ls $db/soft_files/ | cut -d_ -f1 | grep GSE | sort -u); do zcat $db/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; cat ../corpora/lexica/sample_useful_fields.txt) | sed 's/\^SAMPLE = /. . \^SAMPLE = /g' | cut -d' ' -f3- | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | sort -u > $db/sample_info_protocols.txt
done

#Shuffle and split the files for 10-fold cross-validation
for db in CREEDS SNACKKSS_MC; do
cat $db/studies.txt | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $db/shuffled_studies.txt
mkdir $db/split
cd $db/split
split -l $(cat ../shuffled_studies.txt | wc -l | awk '{print int($1 / 4) + 1}') ../shuffled_studies.txt
cd ../..
done

#Clean the annotations
#Our dataset contains any high-throughput sequencing studies, but we only want to train/test on RNA-Seq:
for study in $(ls SNACKKSS_MC/soft_files/ | cut -d_ -f1 | grep GSE | sort -u); do zcat SNACKKSS_MC/soft_files/${study}_family.soft.gz | grep -f <(echo "\^SAMPLE"; echo '!Sample_library_strategy') | paste -s | sed 's/;/$SEMICOLON$/g' | awk '{print $0 ";"}' | sed 's/\t/; /g' | sed 's/\^SAMPLE = /\n/g' | awk '{printstring = $1 "\t"; for(i = 2; i <= NF; i += 1){printstring = printstring " " $i} print printstring}' | sed 's/;\t /\t/g' | rev | cut -d';' -f2- | rev | awk 'NR > 1 {print "'$study'\t" $0}' | sort -u; done | cut -f2,3 | sed 's/!Sample_library_strategy = //g' | sort -u > SNACKKSS_MC/sample_library_strategy.txt
#Get the cleaned-up perturbation table
python3 src/curated_dataset_retrieve_gsms.py ../corpora/SNACKKSS_MC/corrected_curated_dataset.txt <(cat SNACKKSS_MC/sample_info.txt | awk '{print $2 "\t" $0}' | sort -k1,1 | join -t$'\t' - <(cat SNACKKSS_MC/sample_library_strategy.txt | awk '$2 == "RNA-Seq"' | cut -f1 | sort -u) | cut -f2- | sort -u) | awk 'index($1 $2 $3 $4, "#") == 0' > SNACKKSS_MC/perturbations_cleaned.txt



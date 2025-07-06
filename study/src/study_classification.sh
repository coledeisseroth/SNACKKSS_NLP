srcdir=$(dirname "$(realpath $0)")/../../src

OUT_DIR=$1
labelfile=$2
studyinfofile=$3
model=$4
splitdir=$5

#Break the text down into windows that a BERT model can read
python3 $srcdir/chew.py <(cat $labelfile | sort -k1,1 | join -t$'\t' - <(cat $studyinfofile | sed 's/$SEMICOLON$/;/g' | grep -v 'Refer to individual Series. This SuperSeries is composed of the SubSeries listed below.' | sort -k1,1) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3}') $model | awk 'BEGIN {FS = "\t"} {gsub("_", "\t", $1); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {print $1 "_" $3 "\t" $2 "\t" $4}' | sed 's/"//g' | sed 's/\\//g' | sort -u > $OUT_DIR/study_info_chewed.txt

#Assemble the training and testing datasets for cross-validation
mkdir $OUT_DIR/training_datasets
for trial in $(ls $splitdir); do
for split in $(ls $splitdir | grep -vw $trial); do cat $splitdir/$split; done | sort -u | join -t$'\t' - <(cat $OUT_DIR/study_info_chewed.txt | awk 'BEGIN {FS = "_"} {print $1 "\t" $0}' | sort -k1,1) | cut -f3- | awk 'BEGIN {FS = "\t"} {print "{\"text\":\"" $2 "\",\"label\":" $1 "}"}' | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/training_datasets/$trial.json
done

mkdir $OUT_DIR/testing_datasets
for split in $(ls $splitdir); do
cat $OUT_DIR/study_info_chewed.txt | awk 'BEGIN {FS = "_"} {print $1 "\t" $0}' | sort -k1,1 | join -t$'\t' - <(cat $splitdir/$split | sort -u) | cut -f2- | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3}' > $OUT_DIR/testing_datasets/$split.txt
done

cat $OUT_DIR/training_datasets/* | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/final_training_dataset.json

#Train the models
mkdir $OUT_DIR/models
for split in $(ls $splitdir); do
python3 $srcdir/text_classification_finetune.py $OUT_DIR/training_datasets/$split.json $OUT_DIR/models/$split $model
done


srcdir=$(dirname "$(realpath $0)")/../../src

OUT_DIR=$1
labelfile=$2
sampleinfofile=$3
model=$4
splitdir=$5

python3 $srcdir/chew.py <(cat $sampleinfofile | cut -f2- | sort -u | sed 's/$SEMICOLON$/;/g') $model > $OUT_DIR/sample_info_chewed.txt

mkdir $OUT_DIR/training_datasets
for trial in $(ls $splitdir); do
for split in $(ls $splitdir | grep -vw $trial); do cat $splitdir/$split | sort -k1,1 | join -t$'\t' - <(cat $sampleinfofile | cut -f-2 | sort -k1,1) | cut -f2; done | sort -u | join -t$'\t' - <(cat $OUT_DIR/sample_info_chewed.txt | sort -k1,1) | grep -vwf <(cat $splitdir/$trial | sort -u | join -t$'\t' - <(cat $OUT_DIR/sample_info_chewed.txt | cut -f-2 | sort -k1,1) | cut -f2 | sort -u) | sort -k1,1 | join -t$'\t' <(cat $labelfile | sort -k1,1) - | cut -f2,4 | sed 's/"//g' | sed 's/\\//g' | awk 'BEGIN {FS = "\t"} {print "{\"text\":\"" $2 "\",\"label\":" $1 "}"}' | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/training_datasets/$trial.json
done

mkdir $OUT_DIR/testing_datasets
for split in $(ls $splitdir); do
cat $OUT_DIR/sample_info_chewed.txt | sort -k1,1 | join -t$'\t' - <(cat $splitdir/$split | sort -u | join -t$'\t' - <(cat $sampleinfofile | cut -f-2 | sort -k1,1) | cut -f2 | sort -u) | sort -k1,1 | join -t$'\t' <(cat $labelfile | sort -k1,1) - | awk 'BEGIN {FS = "\t"} {print $1 "_" $3 "_" $2 "\t" $4}' > $OUT_DIR/testing_datasets/$split.txt
done

cat $OUT_DIR/training_datasets/* | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/final_training_dataset.json

mkdir $OUT_DIR/models
for split in $(ls $splitdir | grep -vwf <(ls $OUT_DIR/models)); do
python3 $srcdir/text_classification_finetune.py $OUT_DIR/training_datasets/$split.json $OUT_DIR/models/$split $model
done


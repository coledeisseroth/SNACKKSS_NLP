srcdir=$(dirname "$(realpath $0)")/../../src

OUT_DIR=$1
labeledpairsfile=$2
model=$3
splitdir=$4

python3 $srcdir/chew.py <(cat $labeledpairsfile | awk 'BEGIN {FS = "_"} {print $1 "\t" $0}' | sort -k1,1 | cut -f2-) $model | awk 'BEGIN {FS = "\t"} {gsub("_", "\t", $1); print $1 "\t" $2 "\t" $3}' | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "_" $3 "_" $5 "\t" $4 "\t" $6}' | sort -u > $OUT_DIR/labels_chewed.txt

mkdir $OUT_DIR/training_datasets
for split in $(ls $splitdir); do
cat $OUT_DIR/labels_chewed.txt | awk 'BEGIN {FS = "_"} {print $1 "\t" $2 "\t" $3 "\t" $0}' | sort -t$'\t' -k1,1 | join -t$'\t' - <(cat $(ls $splitdir/* | grep -vw $split) | sort -u) | grep -vwf <(cat $splitdir/$split) | grep -vwf <(cat $splitdir/$split | sort -u | join -t$'\t' - <(cat $labeledpairsfile | sed 's/_/\t/g' | awk '{print $1 "\t" $2; print $1 "\t" $3}' | sort -u | sort -k1,1) | cut -f2 | sort -u) | cut -f4- | sort -u > $OUT_DIR/training_datasets/$split.txt
done

mkdir $OUT_DIR/testing_datasets
for split in $(ls $splitdir); do
cat $OUT_DIR/labels_chewed.txt | awk 'BEGIN {FS = "_"} {print $1 "\t" $0}' | sort -k1,1 | join -t$'\t' - <(cat $splitdir/$split | sort -u) | cut -f2- | sort -u > $OUT_DIR/testing_datasets/$split.txt
done

mkdir $OUT_DIR/training_json
for split in $(ls $splitdir); do
cat $OUT_DIR/training_datasets/$split.txt | cut -f2- | sed 's/"//g' | sed 's/\\//g' | awk 'BEGIN {FS = "\t"} {print "{\"text\":\"" $2 "\",\"label\":" $1 "}"}' | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/training_json/$split.json
done

cat $OUT_DIR/training_json/* | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2025" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/final_training_dataset.json

mkdir $OUT_DIR/models
for split in $(ls $splitdir | grep -vwf <(ls $OUT_DIR/models)); do
python3 $srcdir/text_classification_finetune.py $OUT_DIR/training_json/$split.json $OUT_DIR/models/$split $model
done


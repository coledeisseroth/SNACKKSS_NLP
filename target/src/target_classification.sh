srcdir=$(dirname "$(realpath $0)")/../../src
srcdir2=$(dirname "$(realpath $0)")

OUT_DIR=$1
namefile=$2
#Note: This sample info file should include the protocol info, as that is sometimes the only place where the target is mentioned.
sampleinfofile=$3
model=$4
splitdir=$5

python3 $srcdir/chew.py <(cat $sampleinfofile | cut -f2- | sort -u | sed 's/$SEMICOLON$/;/g') $model > $OUT_DIR/sample_info_chewed.txt

cat $OUT_DIR/sample_info_chewed.txt | sort -k1,1 | join -t$'\t' - <(cat $namefile | sort -k1,1) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $4 "\t" $3}' | sort -u > $OUT_DIR/name_labels.txt

mkdir $OUT_DIR/name_labels_train
mkdir $OUT_DIR/name_labels_test
for split in $(ls $splitdir); do
cat $OUT_DIR/name_labels.txt | awk 'BEGIN {FS = "\t"} {gsub("_", "\t", $1); print $1 "\t" $2 "\t" $3}' | sort -k1,1 | join -t$'\t' - <(cat $(ls $splitdir/* | grep -vw $split) | sort -u | join -t$'\t' - <(cat $sampleinfofile | cut -f1,2 | sort -k1,1) | cut -f2 | sort -u) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3 "\t" $4}' > $OUT_DIR/name_labels_train/$split.txt
cat $OUT_DIR/name_labels.txt | awk 'BEGIN {FS = "\t"} {gsub("_", "\t", $1); print $1 "\t" $2 "\t" $3}' | sort -k1,1 | join -t$'\t' - <(cat $(ls $splitdir/$split) | sort -u | join -t$'\t' - <(cat $sampleinfofile | cut -f1,2 | sort -k1,1) | cut -f2 | sort -u | comm -23 - <(cat $OUT_DIR/name_labels_train/$split.txt | cut -f1 | sort -u)) | awk 'BEGIN {FS = "\t"} {print $1 "_" $2 "\t" $3 "\t" $4}' > $OUT_DIR/name_labels_test/$split.txt
done

mkdir $OUT_DIR/position_labels_train
mkdir $OUT_DIR/position_labels_test
mkdir $OUT_DIR/bio_train
mkdir $OUT_DIR/training_datasets
for split in $(ls $splitdir); do
for trial in train test; do python3 $srcdir2/find_names.py <(cat $OUT_DIR/name_labels_${trial}/$split.txt | sed 's/\r//g') | awk 'BEGIN {FS = "\t"} $2 != ""' > $OUT_DIR/position_labels_${trial}/$split.txt; done
python3 $srcdir2/bio_format.py $OUT_DIR/position_labels_train/$split.txt > $OUT_DIR/bio_train/$split.txt
python3 $srcdir2/bio_to_json.py $OUT_DIR/bio_train/$split.txt | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:"2024" -nosalt </dev/zero 2>/dev/null) > $OUT_DIR/training_datasets/$split.json
done

mkdir $OUT_DIR/models
for split in $(ls $splitdir); do
python3 $srcdir/target_finetune.py $OUT_DIR/training_datasets/$split.json $OUT_DIR/models/$split $model
done

mkdir $OUT_DIR/predictions
for split in $(ls $splitdir); do
python3 $srcdir/indy_target_predict.py <(cat $OUT_DIR/name_labels_test/$split.txt | cut -f1,3 | sort -u) $OUT_DIR/models/$split > $OUT_DIR/predictions/$split.txt
done

mkdir $OUT_DIR/predictions_merged
for split in $(ls $splitdir); do
python3 $srcdir/merge_entities.py $OUT_DIR/predictions/$split.txt > $OUT_DIR/predictions_merged/$split.txt
done


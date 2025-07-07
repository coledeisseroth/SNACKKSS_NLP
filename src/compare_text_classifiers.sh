srcdir=$(dirname "$(realpath $0)")

OUT_DIR=$1
models1=$2
models2=$3
train1=$4
train2=$5
test1=$6
test2=$7

mkdir $OUT_DIR/models12
for split in $(ls $models1 | sort -u | comm -23 - <(ls $OUT_DIR/models12/ | sort -u)); do
python3 $srcdir/text_classification_finetune.py $train2/$split.json $OUT_DIR/models12/$split $models1/$split
done

mkdir $OUT_DIR/models21
for split in $(ls $models1 | sort -u | comm -23 - <(ls $OUT_DIR/models21/ | sort -u)); do
python3 $srcdir/text_classification_finetune.py $train1/$split.json $OUT_DIR/models21/$split $models2/$split
done

mkdir $OUT_DIR/predictions2.2
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $models2/$split $test2/$split.txt 0 > $OUT_DIR/predictions2.2/$split.txt
done

mkdir $OUT_DIR/predictions1.1
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $models1/$split $test1/$split.txt 0 > $OUT_DIR/predictions1.1/$split.txt
done

mkdir $OUT_DIR/predictions2.1
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $models2/$split $test1/$split.txt 0 > $OUT_DIR/predictions2.1/$split.txt
done

mkdir $OUT_DIR/predictions12.1
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $OUT_DIR/models12/$split $test1/$split.txt 0 > $OUT_DIR/predictions12.1/$split.txt
done

mkdir $OUT_DIR/predictions21.1
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $OUT_DIR/models21/$split $test1/$split.txt 0 > $OUT_DIR/predictions21.1/$split.txt
done

mkdir $OUT_DIR/predictions1.2
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $models1/$split $test2/$split.txt 0 > $OUT_DIR/predictions1.2/$split.txt
done

mkdir $OUT_DIR/predictions12.2
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $OUT_DIR/models12/$split $test2/$split.txt 0 > $OUT_DIR/predictions12.2/$split.txt
done

mkdir $OUT_DIR/predictions21.2
for split in $(ls $models1); do
python3 $srcdir/text_classification_predict.py $OUT_DIR/models21/$split $test2/$split.txt 0 > $OUT_DIR/predictions21.2/$split.txt
done


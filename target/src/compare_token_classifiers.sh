srcdir=$(dirname "$(realpath $0)")

OUT_DIR=$1
models1=$2
models2=$3
train1=$4
train2=$5
test1=$6
test2=$7

mkdir $OUT_DIR/models12
for split in $(ls $models1); do
python3 $srcdir/target_finetune.py $train2/$split.json $OUT_DIR/models12/$split $models1/$split
done

mkdir $OUT_DIR/models21
for split in $(ls $models1); do
python3 $srcdir/target_finetune.py $train1/$split.json $OUT_DIR/models21/$split $models2/$split
done

mkdir $OUT_DIR/predictions1.1
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test1/$split.txt | cut -f1,3 | sort -u) $models1/$split > $OUT_DIR/predictions1.1/$split.txt
done

mkdir $OUT_DIR/predictions2.1
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test1/$split.txt | cut -f1,3 | sort -u) $models2/$split > $OUT_DIR/predictions2.1/$split.txt
done

mkdir $OUT_DIR/predictions12.1
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test1/$split.txt | cut -f1,3 | sort -u) $OUT_DIR/models12/$split > $OUT_DIR/predictions12.1/$split.txt
done

mkdir $OUT_DIR/predictions21.1
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test1/$split.txt | cut -f1,3 | sort -u) $OUT_DIR/models21/$split > $OUT_DIR/predictions21.1/$split.txt
done

mkdir $OUT_DIR/predictions1.2
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test2/$split.txt | cut -f1,3 | sort -u) $models1/$split > $OUT_DIR/predictions1.2/$split.txt
done

mkdir $OUT_DIR/predictions2.2
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test2/$split.txt | cut -f1,3 | sort -u) $models2/$split > $OUT_DIR/predictions2.2/$split.txt
done

mkdir $OUT_DIR/predictions12.2
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test2/$split.txt | cut -f1,3 | sort -u) $OUT_DIR/models12/$split > $OUT_DIR/predictions12.2/$split.txt
done

mkdir $OUT_DIR/predictions21.2
for split in $(ls $models1); do
python3 $srcdir/target_predict.py <(cat $test2/$split.txt | cut -f1,3 | sort -u) $OUT_DIR/models21/$split > $OUT_DIR/predictions21.2/$split.txt
done

for train in 1 2 12 21; do for test in 1 2; do
mkdir $OUT_DIR/predictions${train}.${test}_merged
for split in $(ls $models1); do
python3 $srcdir/merge_entities.py $OUT_DIR/predictions${train}.${test}/$split.txt > $OUT_DIR/predictions${train}.${test}_merged/$split.txt
done
done; done


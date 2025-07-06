import sys
import os
from collections import defaultdict
from datasets import load_dataset
from datasets import Dataset
from datasets import DatasetDict
import torch

textfile = sys.argv[1]
ckpt = sys.argv[2]

from transformers import pipeline

classifier = pipeline("ner", model=ckpt)

for line in open(sys.argv[1]):
    line = line.strip().split("\t")
    if len(line) < 2: continue
    line_index = line[0]
    line = line[1]
    results = classifier(line)
    entities = []
    curStart = None
    curEnd = None
    curType = None
    for i in range(len(results)):
        result = results[i]
        label = result['entity']
        if label == "O":
            if curStart is not None and curEnd is not None and curType is not None: entities.append(str(curStart) + "-" + str(curEnd) + ":" + str(curType))
            curStart = None
            curType = None
            curEnd = None
            continue
        etype = label.split('-')[1]
        progress = label.split('-')[0]
        if progress == "B":
            if curStart is not None and curEnd is not None and curType is not None: entities.append(str(curStart) + "-" + str(curEnd) + ":" + str(curType))
            curStart = result['start']
            curType = etype
            curEnd = result['end']
        if progress == "I": curEnd = result['end']
    if curStart is not None and curEnd is not None and curType is not None: entities.append(str(curStart) + "-" + str(curEnd) + ":" + str(curType))
    print(str(line_index) + "\t" + ";".join(entities) + "\t" + line)



import sys
import os
from collections import defaultdict

bio_file = sys.argv[1]

def is_numeric(token):
    try:
        int(token)
        return True
    except ValueError: return False

all_labels = ["O"]
for line in ["GENE", "CHEM"]:
    all_labels.append("B-" + line)
    all_labels.append("I-" + line)

label2id = {}
for i in range(len(all_labels)):
    label2id[all_labels[i]] = str(i)

tokens = []
ner_tags = []
id_no = 0

for line in open(bio_file):
    line = line.strip()
    if not line:
        if tokens and ner_tags: print('{"id":"' + str(id_no) + '","tokens":[' + ",".join(tokens) + '],"ner_tags":[' + ",".join(ner_tags) + ']}')
        id_no += 1
        tokens = []
        ner_tags = []
        continue
    line = line.split("\t")
    if len(line) < 2: continue
    token = line[0].replace('"', "").replace('\\', '')
    if not token: continue
    if len(tokens) > 2 and tokens[-1].split('"')[1] == '.' and not (is_numeric(token) and is_numeric(tokens[-2].split('"')[1])):
        print('{"id":"' + str(id_no) + '","tokens":[' + ",".join(tokens) + '],"ner_tags":[' + ",".join(ner_tags) + ']}')
        id_no += 1
        tokens = []
        ner_tags = []
    tokens.append('"' + token + '"')
    ner_tags.append(label2id[line[1]])

if tokens and ner_tags: print('{"id":"' + str(id_no) + '","tokens":[' + ",".join(tokens) + '],"ner_tags":[' + ",".join(ner_tags) + ']}')


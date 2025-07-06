import sys
import os
from collections import defaultdict

for line in open(sys.argv[1]):
    line = line.strip().split("\t")
    pmid = line[0]
    positions = line[1].split(";")
    text = line[2]
    if not positions[0]: positions = []
    for i in range(len(positions)):
        positions[i] = positions[i].split(":")
        positions[i][0] = positions[i][0].split("-")
        positions[i] = [positions[i][1], [int(positions[i][0][0]), int(positions[i][0][1])]]
    positions.sort(key=(lambda x: x[1][1]))
    labeled_segments = []
    while text and positions:
        if positions[-1][1][1] <= len(text):
            labeled_segments.append((len(labeled_segments), text[positions[-1][1][1]:], "O"))
            text = text[:positions[-1][1][1]+1]
        labeled_segments.append((len(labeled_segments), text[positions[-1][1][0]:positions[-1][1][1]], "B-" + positions[-1][0]))
        text = text[:positions[-1][1][0]]
        positions = positions[:-1]
    if text: labeled_segments.append((len(labeled_segments), text, "O"))
    labeled_segments.sort(key=(lambda x: x[0]), reverse=True)
    for segment in labeled_segments:
        tokens = segment[1].split(' ')
        label = segment[2]
        for i in range(len(tokens)):
            token = tokens[i]
            if not token: continue
            if (i == 0 or i == len(tokens) - 1) and not token.isalnum():
                print(token + "\t" + "O")
                continue
            print (token + "\t" + label)
            if label == "B-GENE": label = "I-GENE"
            if label == "B-CHEM": label = "I-CHEM"
    print()


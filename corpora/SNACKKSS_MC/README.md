This command was run on May 20, 2024:
#curl 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term="Expression+profiling+by+high+throughput+sequencing"\[Filter\]+AND+gse\[ETYP\]&retmax=500000' | grep '<Id>' | cut -d'>' -f2 | cut -d'<' -f1 > datasets.txt

Then it was shuffled with the random seed of the then-current year:
#cat datasets.txt | sort -u | shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:2024 -nosalt </dev/zero 2>/dev/null) > datasets_shuffled.txt

Then we manually annotated the first 625 of the GEO series in this shuffled list, resulting in curated_dataset.txt

We then made a quick pass through this curated dataset and made corrections as deemed appropriate, resulting in corrected_curated_dataset.txt

Lastly, we manually established a list of features that, when different between two samples, would generally be prohibitive of considering one a control to the other, resulting in control_prohibitive_features.txt. This was not used in training nor testing, but when running the final pipeline, applying this rule-based filter cuts a tremendous amount of unnecessary runtime from the control classification.


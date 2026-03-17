# SNACKKSS_NLP
The pipeline that trains and evaluates BERT models in curation of gene-disruption and drug-treatment studies in the Gene Expression Omnibus

# Docker version
You can build and run a Docker image for this pipeline as follows:

docker build -t snackkss-nlp-pipeline .

docker save -o snackkss-nlp-pipeline.tar snackkss-nlp-pipeline

docker rmi snackkss-nlp-pipeline

docker load -i snackkss-nlp-pipeline.tar

docker run -v $(pwd)/:/app/ snackkss-nlp-pipeline

# Licensing and disclaimer:
SNACKKSS provides no warranty whatsoever for how its predictions are used. Furthermore, it should never be used to guide medical decision-making. SNACKKSS is licensed under the Creative Commons License v4.0. 

# SNACKKSS_NLP
The pipeline that trains and evaluates BERT models in curation of gene-disruption and drug-treatment studies in the Gene Expression Omnibus

#Docker version
You can build and run a Docker image for this pipeline as follows:
docker build -t snackkss-nlp-pipeline .
docker save -o snackkss-nlp-pipeline.tar snackkss-nlp-pipeline
docker rmi snackkss-nlp-pipeline
docker load -i snackkss-nlp-pipeline.tar
docker run -u $(whoami) -v $(pwd)/:/app/ snackkss-nlp-pipeline


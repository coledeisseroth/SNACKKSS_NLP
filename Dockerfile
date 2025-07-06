FROM ubuntu
USER testuser
RUN apt-get install python3.10.12
RUN apt install wget
RUN pip3 install -r /opt/python_requirements.txt

############################################################
# Dockerfile for gdc-client
# Based on Ubuntu Linux
############################################################

FROM ubuntu:latest

# Install dependencies
RUN apt-get update -y && apt-get install -y \
    unzip \
    curl && \
    rm -rf /var/lib/apt/lists/* 

WORKDIR /tmp
# Download and install gdc-client
RUN curl -L -o /tmp/gdc-client_2.3_Ubuntu_x64-py3.8-ubuntu-20.04.zip https://gdc.cancer.gov/system/files/public/file/gdc-client_2.3_Ubuntu_x64-py3.8-ubuntu-20.04.zip && \
    unzip /tmp/gdc-client_2.3_Ubuntu_x64-py3.8-ubuntu-20.04.zip && \
    unzip /tmp/gdc-client_2.3_Ubuntu_x64.zip && \
    mv gdc-client /usr/bin/gdc-client && \
    chmod +x /usr/bin/gdc-client && \
    rm -rf /tmp/gdc-client*



############################################################
# Dockerfile for BROAD GRO share-seq-pipeline
# Single-stage, no custom user
############################################################

FROM debian:bookworm-slim

LABEL maintainer="Siddarth Wekhande"
LABEL software.organization="Broad Institute of MIT and Harvard"
LABEL software.task="FeatureCounts+samtools"

ENV DEBIAN_FRONTEND=noninteractive
ENV SAMTOOLS_VERSION=1.9
ENV FEATURECOUNTS_VERSION=2.0.2

# Install build dependencies and cleanup after
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    liblz4-dev \
    liblzma-dev \
    libncurses5-dev \
    libbz2-dev \
    wget \
    zlib1g-dev \
    ca-certificates \
    bash \
    coreutils \
    unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

# Build samtools 1.9
RUN git clone --branch ${SAMTOOLS_VERSION} --single-branch https://github.com/samtools/samtools.git && \
    git clone --branch ${SAMTOOLS_VERSION} --single-branch https://github.com/samtools/htslib.git && \
    cd samtools && make && make install && cd .. && rm -rf samtools htslib

# Build featureCounts (subread suite)
RUN wget -q https://sourceforge.net/projects/subread/files/subread-${FEATURECOUNTS_VERSION}/subread-${FEATURECOUNTS_VERSION}-source.tar.gz && \
    tar -xzf subread-${FEATURECOUNTS_VERSION}-source.tar.gz && \
    cd subread-${FEATURECOUNTS_VERSION}-source/src && \
    make -f Makefile.Linux && \
    mv ../bin/* /usr/local/bin/ && \
    cd /tmp/build && rm -rf subread-${FEATURECOUNTS_VERSION}-source subread-${FEATURECOUNTS_VERSION}-source.tar.gz
    
RUN cd / && rm -rf /tmp/build

WORKDIR /
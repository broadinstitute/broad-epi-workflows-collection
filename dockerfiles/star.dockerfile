FROM debian:bookworm-slim

LABEL maintainer="Siddarth Wekhande"
LABEL component="STAR+samtools"

ENV DEBIAN_FRONTEND=noninteractive

# Basic packages + runtime libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    unzip \
    bash \
    coreutils \
    libncurses6 \
    libgomp1 \
    liblzma5 \
    zlib1g \
    libbz2-1.0 \
    samtools \
 && rm -rf /var/lib/apt/lists/*

# Install STAR 2.7.10a (static release)
RUN wget -q https://github.com/alexdobin/STAR/releases/download/2.7.10a_alpha_220818/STAR_2.7.10a_alpha_220818_Linux_x86_64_static.zip \
    && unzip STAR_2.7.10a_alpha_220818_Linux_x86_64_static.zip \
    && mv STAR /usr/local/bin/ \
    && rm STAR_2.7.10a_alpha_220818_Linux_x86_64_static.zip


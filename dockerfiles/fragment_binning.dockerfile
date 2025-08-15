# Build an image that can convert fragments → bigWig → binned counts
FROM mambaorg/micromamba:1.5.8

USER root

# Install tools: bedtools and UCSC utilities
RUN micromamba install -y -n base -c conda-forge -c bioconda \
      bedtools \
      ucsc-bedgraphtobigwig \
      ucsc-bigwigaverageoverbed \
    && micromamba clean -a -y

ENV PATH=/opt/conda/bin:$PATH

# Default to bash; WDL can override to call the helper
CMD ["/bin/bash"]

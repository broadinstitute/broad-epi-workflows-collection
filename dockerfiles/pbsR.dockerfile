FROM rocker/r-base 

LABEL maintainer = "Siddarh Wekhande"
LABEL software = "pbsR"

RUN apt-get update && apt-get install -y git

RUN git clone https://github.com/broadinstitute/pbs-analysis.git && \
    cd pbs-analysis && \
    git checkout sw-pbs

RUN Rscript -e "install.packages(c('BiocManager','dplyr','pkgload', 'remotes')); BiocManager::install(c('Rsubread'));" 
RUN Rscript -e "install.packages(c('patchwork', 'goftest', 'fBasics', 'ggplot2', 'foreach'))"
#RUN cd pbs-analysis && Rscript -e "pkgload::load_all('pbsR')"
RUN Rscript -e "install.packages(c('plyr'))"

ADD ../src/R/pbsR_script.R ./
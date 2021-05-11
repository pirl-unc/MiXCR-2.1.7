# mixcr_2.1.7:1
FROM phusion/baseimage:0.9.19

USER root

# install tools
RUN \
  apt-get update && \
  apt-get install -yq \
    default-jdk \
    unzip \
    perl \
    wget && \
  apt-get clean  

# install mixcr 2.1.7
RUN \
  cd /opt && \
  wget https://github.com/milaboratory/mixcr/releases/download/v2.1.7/mixcr-2.1.7.zip && \
  unzip -o mixcr-2.1.7.zip && \
  rm mixcr-2.1.7.zip && \
  ln -s /opt/mixcr-2.1.7/mixcr /usr/local/bin

#install IMGT library
RUN \
  cd /opt/mixcr-2.1.7/libraries && \
  wget https://github.com/repseqio/library-imgt/releases/download/v1/imgt.201631-4.sv1.json.gz && \
  gunzip imgt.201631-4.sv1.json.gz
  # Download FastQC

# Install FastQC
ADD http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip /tmp/
RUN cd /usr/local && \
    unzip /tmp/fastqc_*.zip && \
    chmod 755 /usr/local/FastQC/fastqc && \
    ln -s /usr/local/FastQC/fastqc /usr/local/bin/fastqc && \
    rm -rf /tmp/fastqc_*.zip

# setup user for lbgcluster
RUN groupadd -g 1000 lbg \
   && groupadd -g 1026 nextgenseq \
   && groupadd -g 1062 seqgroup \
   && groupadd -g 1063 clinseq \
   && groupadd -g 1075 datasharing \
   && groupadd -g 2650 lbginrc \
   && groupadd -g 2782 lbgseq \
   && groupadd -g 2790 seq-in \
   && groupadd -g 2791 seq-out \
   && groupadd -g 3011 lccc_instrument \
   && groupadd -g 3026 lccc_gpath \
   && groupadd -g 3029 bioinf \
   && groupadd -g 3035 lccc_ram \
   && useradd -u 209755 -g 1000 \
              -G 1026,1062,1063,1075,2650,2782,2790,2791,3011,3026,3029,3035 \
              -s /bin/bash -N -c "Service account for Sequencing" seqware

RUN mkdir -p /home/seqware \
   && chown seqware /home/seqware \
   && chgrp lbg /home/seqware \
   && chmod 775 /home/seqware

# installing R
RUN \
  apt-get update && \
  apt-get -yq install r-base r-base-dev && \
  apt-get -yq install libatlas3-base && \
  Rscript -e 'install.packages("vegan", repos="https://cran.rstudio.com")'

COPY import/ /import/

RUN apt-get clean

USER seqware


# set environt variables
ENV CHAINS "ALL"

# RNA_SEQ values are true or false
# runs with rna seq parameters if set to true
ENV RNA_SEQ true

# USE_EXISTING_VDJCA values are true or false
# looks for and uses existing VDJCA file if this is set to true
ENV USE_EXISTING_VDJCA false

ENV SPECIES "hsa"
ENV THREADS 1
ENV INPUT_PATH_1 ""
ENV INPUT_PATH_2 ""
ENV OUTPUT_DIR ""
ENV SAMPLE_NAME "no_sample_name_specified"

# once debugged switch to
# bash -c 'source /import/run_mixcr.sh \
# bash -c 'source /datastore/alldata/shiny-server/rstudio-common/dbortone/docker/mixcr/mixcr_2.1.7/import/run_mixcr.sh \

CMD \
 bash -c 'source /datastore/alldata/shiny-server/rstudio-common/dbortone/docker/mixcr/mixcr_2.1.7/import/run_mixcr.sh \
 --chains "${CHAINS}" \
 --rna_seq "${RNA_SEQ}" \
 --use_existing_vdjca "${USE_EXISTING_VDJCA}" \
 --species "${SPECIES}" \
 --threads "${THREADS}" \
 --r1_path "${INPUT_PATH_1}" \
 --r2_path "${INPUT_PATH_2}" \
 --output_dir "${OUTPUT_DIR}" \
 --sample_name "${SAMPLE_NAME}"'

# If you are building an image to a previously existing <sometool>:<version> you need to pull the changes to all of the docker nodes.
# removing the image before rebuilding it isn't enough.
# srun --pty -c 2 --mem 1g -w c6145-docker-2-0.local -p docker bash
# cd /datastore/alldata/shiny-server/rstudio-common/dbortone/docker/mixcr/mixcr_2.1.7
# docker build -t dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1 .
# docker tag dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1 mixcr_2.1.7:1
# docker push dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1
# exit
# srun --pty -c 2 --mem 1g -w fc830-docker-2-0.local -p docker bash
# docker pull dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1
# docker tag dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1 mixcr_2.1.7:1
# docker run --rm=true -it -v /datastore:/datastore:shared dockerreg.bioinf.unc.edu:5000/mixcr_2.1.7:1 /bin/bash

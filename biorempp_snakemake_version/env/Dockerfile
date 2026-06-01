FROM rocker/tidyverse:4.4@sha256:7b6ad006caffcbae246f8f3e761a2ec268b2101a25d54266a27c1bce6ced0689

LABEL maintainer="BioRemPP Development Team"
LABEL description="BioRemPP Snakemake pipeline"
LABEL version="1.1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    libdatrie-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    default-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY env/python-requirements.txt /tmp/python-requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/python-requirements.txt

RUN R -e "\
  install.packages('remotes', repos='https://cloud.r-project.org/', quiet=TRUE); \
  remotes::install_version('dplyr',    version='1.1.4', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('readxl',   version='1.4.3', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('tidyr',    version='1.3.1', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('stringr',  version='1.5.1', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('readr',    version='2.1.5', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('jsonlite', version='1.8.8', repos='https://cloud.r-project.org/', upgrade='never'); \
  remotes::install_version('writexl',  version='1.5.0', repos='https://cloud.r-project.org/', upgrade='never')"

WORKDIR /workspace

CMD ["snakemake", "--snakefile", "Snakefile", "--configfile", "config/config.yaml", "--cores", "2", "--printshellcmds"]

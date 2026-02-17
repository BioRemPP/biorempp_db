FROM rocker/tidyverse:4.3

LABEL maintainer="BioRemPP Development Team"
LABEL description="BioRemPP Snakemake pipeline"
LABEL version="1.0.0"

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
RUN pip3 install --no-cache-dir -r /tmp/python-requirements.txt

COPY env/r-packages.txt /tmp/r-packages.txt
RUN R -e "pkgs <- scan('/tmp/r-packages.txt', what='character', quiet=TRUE); install.packages(pkgs, repos='https://cloud.r-project.org/')"

WORKDIR /workspace

CMD ["snakemake", "--snakefile", "Snakefile", "--configfile", "config/config.yaml", "--cores", "2", "--printshellcmds"]

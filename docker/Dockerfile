FROM ubuntu:latest


LABEL author="Matt Wyczalkowski" \
      maintainer="m.wyczalkowski@wustl.edu"

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    jq \
    libnss-sss \
    samtools \
    vim \
    wget \
    zip \
    && apt-get clean

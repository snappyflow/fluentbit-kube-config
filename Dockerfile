FROM snappyflowml/fluent-bit-custom:latest as builder

# Configuration files
RUN mkdir -p /etc/td-agent-bit && rm -rf /etc/td-agent-bit/*
ADD . /etc/td-agent-bit/
RUN ls -l /etc/td-agent-bit

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mmdb-bin


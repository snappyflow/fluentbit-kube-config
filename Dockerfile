FROM snappyflowml/fluent-bit-custom:latest as builder

# Configuration files
RUN rm -rf /etc/td-agent-bit/*
ADD . /etc/td-agent-bit/
RUN ls -l /etc/td-agent-bit


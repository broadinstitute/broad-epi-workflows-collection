FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gzip \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "scatac-fragment-tools[pybigtools]==0.1.5"

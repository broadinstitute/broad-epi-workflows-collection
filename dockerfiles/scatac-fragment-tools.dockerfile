FROM rust:1-bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-dev \
        clang \
        libclang-dev \
        llvm-dev \
        pkg-config \
        zlib1g-dev \
        gzip \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ENV LIBCLANG_PATH=/usr/lib/llvm-14/lib
ENV LD_LIBRARY_PATH=/usr/lib/llvm-14/lib

RUN pip install --upgrade pip setuptools wheel maturin && \
    pip install "scatac-fragment-tools[pybigtools]==0.1.5"
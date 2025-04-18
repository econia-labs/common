FROM rust:1.86.0-slim-bookworm
RUN cargo install cargo-chef@0.1.71
RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.39.5* \
    && rm -rf /var/lib/apt/lists/*
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

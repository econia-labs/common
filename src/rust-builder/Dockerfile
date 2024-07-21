FROM rust:1.79.0-slim-bookworm
RUN cargo install cargo-chef@0.1.67
RUN apt-get update && apt-get install -y --no-install-recommends \
    git-svn \
    && rm -rf /var/lib/apt/lists/*
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

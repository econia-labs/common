# cspell:word libudev
# cspell:word libclang
# cspell:word libpq
# cspell:word libdw
# cspell:word localnet
# cspell:word rustflags

ARG BUILDER_VERSION=1.1.0
ARG GIT_REPO=https://github.com/aptos-labs/aptos-core.git
ARG CLI_VERSION
ARG GIT_TAG="aptos-cli-v$CLI_VERSION"
ARG CLI_BINARY=/aptos-core/target/cli/aptos

# Configure base image with buildtime dependencies.
FROM econialabs/rust-builder:$BUILDER_VERSION AS base
WORKDIR /app
RUN apt-get update                                \
    && apt-get install --no-install-recommends -y \
        libudev-dev=252*                          \
        build-essential=12*                       \
        libclang-dev=1:14*                        \
        libpq-dev=15*                             \
        libssl-dev=3*                             \
        libdw-dev=0.188*                          \
        pkg-config=1.8*                           \
        lld=1:14*                                 \
        curl=7*                                   \
    && rm -rf /var/lib/apt/lists/*

# Plan build recipe.
FROM base AS planner
ARG GIT_REPO
ARG GIT_TAG
RUN git clone $GIT_REPO --branch $GIT_TAG --depth 1
WORKDIR /app/aptos-core
RUN cargo chef prepare --bin aptos --package aptos --profile cli

# Cache crate dependencies, compile the binary, strip it to reduce its size.
FROM base AS builder
ARG GIT_REPO
ARG GIT_TAG
COPY --from=planner /app/aptos-core/recipe.json recipe.json
RUN cargo chef cook --bin aptos --package aptos --profile cli
RUN git clone $GIT_REPO --branch $GIT_TAG --depth 1
ENV RUSTFLAGS="--cfg tokio_unstable"
RUN cargo build                                \
        --bin aptos                            \
        --manifest-path /aptos-core/Cargo.toml \
        --profile cli                          \
    && strip -s $CLI_BINARY

# Install runtime dependencies, copy binary, set assorted container configs.
FROM debian:bookworm-slim AS runtime
ARG CLI_BINARY
WORKDIR /app
RUN apt-get update                                \
    && apt-get install --no-install-recommends -y \
        ca-certificates=2023*                     \
        curl=7*                                   \
        git=1:2.39*                               \
        jq=1.6*                                   \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/local/bin:$PATH
COPY --from=builder $CLI_BINARY /usr/local/bin
COPY src/aptos-cli/sh/healthcheck.sh sh/healthcheck.sh
RUN chmod +x /app/sh/healthcheck.sh

STOPSIGNAL SIGKILL

HEALTHCHECK            \
    --interval=5s      \
    --timeout=5s       \
    --start-period=60s \
    --retries=10       \
    CMD [ "bash", "sh/healthcheck.sh" ]

# Note that the `--bind-to 0.0.0.0` flag is required to undo the default CLI
# behavior of binding to 127.0.0.1 since `aptos` v2.3.2.
# This is because the CLI is assumed to not be running inside a container, and
# issues can arise on Windows when binding to 0.0.0.0.
# See: https://github.com/aptos-labs/aptos-core/commit/d8eef35
ENTRYPOINT [              \
    "aptos",              \
    "node",               \
    "run-localnet",       \
    "--with-indexer-api", \
    "--bind-to",          \
    "0.0.0.0"             \
]

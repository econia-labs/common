# Specifying package versions in `apt-get` commands can cause
# multi-architecture builds to fail, so the hadolint rule for
# version specification is disabled in this file.
# hadolint global ignore=DL3008
# cspell:word RUSTFLAGS
# cspell:word hadolint
# cspell:word libudev
# cspell:word libclang
# cspell:word libpq
# cspell:word libdw

ARG GIT_REPO=https://github.com/aptos-labs/aptos-core.git
ARG CLI_VERSION
ARG GIT_TAG="aptos-cli-v$CLI_VERSION"
ARG CLI_BINARY=/aptos-core/target/cli/aptos

FROM rust:1-bookworm AS aptos-cli

ARG GIT_REPO
ARG GIT_TAG
ARG CLI_BINARY

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN git clone $GIT_REPO --branch $GIT_TAG --depth 1 \
    && apt-get update && apt-get install --no-install-recommends -y \
        libudev-dev=252* \
        build-essential=12* \
        libclang-dev=1:14* \
        libpq-dev=15* \
        libssl-dev=3* \
        libdw-dev=0.188* \
        pkg-config=1.8* \
        lld=1:14* \
        curl=7* \
    && rm -rf /var/lib/apt/lists/*

# Resolve outdated lockfile from upstream tag, build the binary,
# and strip it to reduce its size.
RUN cargo update --manifest-path /aptos-core/Cargo.toml && \
    RUSTFLAGS="--cfg tokio_unstable" cargo build \
    --bin aptos \
    --manifest-path /aptos-core/Cargo.toml \
    --profile cli && \
    strip -s $CLI_BINARY

FROM ubuntu:noble
WORKDIR /app

# Copy the executable to `/usr/local/bin` and add it to the PATH.
ENV PATH=/usr/local/bin:$PATH
ARG CLI_BINARY
COPY --from=aptos-cli $CLI_BINARY /usr/local/bin

STOPSIGNAL SIGKILL

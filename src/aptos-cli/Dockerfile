# Specifying package versions in `apt-get` commands can cause
# multi-architecture builds to fail, so the hadolint rule for
# version specification is disabled in this file.
# hadolint global ignore=DL3008
# cspell:word hadolint
# cspell:word libudev
# cspell:word libclang
# cspell:word libpq
# cspell:word libdw
# cspell:word localnet
# cspell:word rustflags

ARG GIT_REPO=https://github.com/aptos-labs/aptos-core.git
ARG CLI_VERSION
ARG GIT_TAG="aptos-cli-v$CLI_VERSION"
ARG CLI_BINARY=/aptos-core/target/cli/aptos

FROM rust:1-bookworm AS aptos-cli

ARG GIT_REPO
ARG GIT_TAG
ARG CLI_BINARY

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN git clone $GIT_REPO --branch $GIT_TAG --depth 1  \
    && apt-get update                                \
    && apt-get install --no-install-recommends -y    \
        libudev-dev=252*                             \
        build-essential=12*                          \
        libclang-dev=1:14*                           \
        libpq-dev=15*                                \
        libssl-dev=3*                                \
        libdw-dev=0.188*                             \
        pkg-config=1.8*                              \
        lld=1:14*                                    \
        curl=7*                                      \
    && rm -rf /var/lib/apt/lists/*

# Resolve outdated lockfile from upstream tag, build the binary,
# and strip it to reduce its size.
RUN cargo update --manifest-path /aptos-core/Cargo.toml  \
    && RUSTFLAGS="--cfg tokio_unstable" cargo build      \
        --bin aptos                                      \
        --manifest-path /aptos-core/Cargo.toml           \
        --profile cli                                    \
    && strip -s $CLI_BINARY

FROM ubuntu:noble
ARG CLI_BINARY

RUN apt-get update                                 \
    && apt-get install --no-install-recommends -y  \
        ca-certificates=2024*                      \
        curl=8.5*                                  \
        git=1:2.43*                                \
        jq=1.7*                                    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PATH=/usr/local/bin:$PATH
COPY --from=aptos-cli $CLI_BINARY /usr/local/bin

COPY src/aptos-cli/sh/healthcheck.sh sh/healthcheck.sh
RUN chmod +x /app/sh/healthcheck.sh

STOPSIGNAL SIGKILL

HEALTHCHECK                                   \
    --interval=5s                             \
    --timeout=5s                              \
    --start-period=60s                        \
    --retries=10                              \
    CMD [ "bash", "sh/healthcheck.sh" ]

# Note that the `--bind-to 0.0.0.0` flag is required to undo the default CLI
# behavior of binding to 127.0.0.1 since `aptos` v2.3.2.
# This is because the CLI is assumed to not be running inside a container, and
# issues can arise on Windows when binding to 0.0.0.0.
# See: https://github.com/aptos-labs/aptos-core/commit/d8eef35
ENTRYPOINT [               \
    "aptos",               \
    "node",                \
    "run-localnet",        \
    "--with-indexer-api",  \
    "--bind-to",           \
    "0.0.0.0"              \
]

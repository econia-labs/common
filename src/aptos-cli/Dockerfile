# cspell:word libudev
# cspell:word libclang
# cspell:word libpq
# cspell:word libdw
# cspell:word localnet
# cspell:word rustflags

ARG BUILDER_VERSION=1.1.0
# Default to compile using as many logical CPUs as possible.
ARG CARGO_BUILD_JOBS=-1
ARG CLI_BINARY=aptos-core/target/cli/aptos
ARG CLI_VERSION
ARG GIT_REPO=https://github.com/aptos-labs/aptos-core.git
ARG GIT_TAG="aptos-cli-v$CLI_VERSION"

# Install buildtime dependencies.
FROM econialabs/rust-builder:$BUILDER_VERSION AS builder
ARG CARGO_BUILD_JOBS
ARG CLI_BINARY
ARG GIT_REPO
ARG GIT_TAG
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
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

# Clone aptos-core, update a known offending dependency, build the CLI binary
# using specified number of parallel jobs, then strip it.
RUN git clone $GIT_REPO --branch $GIT_TAG --depth 1
WORKDIR /aptos-core
RUN cargo update --package time \
    && cargo build --bin aptos --jobs $CARGO_BUILD_JOBS --profile cli
WORKDIR /
RUN strip -s "$CLI_BINARY"

# Install runtime dependencies, copy over binary.
FROM debian:bookworm-slim AS runtime
ARG CLI_BINARY
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates=2023* \
        curl=7* \
        git=1:2.39* \
    && rm -rf /var/lib/apt/lists/*

# Store the jq release page base URL in a variable and interpolate the proper
# target architecture for `curl`, since `jq-1.7` is not available in the debian
# `apt` packages.
# hadolint ignore=DL4006
RUN BASE_URL="https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux" \
    && ARCH=$(uname -m) \
    && case "${ARCH}" in \
         "x86_64") JQ_ARCH="amd64" ;; \
         "aarch64") JQ_ARCH="arm64" ;; \
         *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
       esac \
    && curl -L -o /usr/local/bin/jq "${BASE_URL}-${JQ_ARCH}" \
    && chmod +x /usr/local/bin/jq \
    && jq --version | grep 'jq-1.7'

COPY --from=builder $CLI_BINARY /usr/local/bin

# Copy over healthcheck script, make it executable so it can be run.
WORKDIR /
COPY src/aptos-cli/sh/healthcheck.sh sh/healthcheck.sh
RUN chmod +x sh/healthcheck.sh
HEALTHCHECK \
    --interval=5s \
    --timeout=5s \
    --start-period=60s \
    --retries=10 \
    CMD [ "bash", "sh/healthcheck.sh" ]

# Note that the `--bind-to 0.0.0.0` flag is required to undo the default CLI
# behavior of binding to 127.0.0.1 since `aptos` v2.3.2.
# This is because the CLI is assumed to not be running inside a container, and
# issues can arise on Windows when binding to 0.0.0.0.
# See: https://github.com/aptos-labs/aptos-core/commit/d8eef35
ENTRYPOINT [ \
    "aptos", \
    "node", \
    "run-localnet", \
    "--with-indexer-api", \
    "--bind-to", \
    "0.0.0.0" \
]

STOPSIGNAL SIGKILL

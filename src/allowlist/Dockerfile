# cspell:word hadolint
ARG BINARY=allowlist

# Declare base image and working directory.
FROM econialabs/muslrust-chef:1.0.0 AS base
WORKDIR /app

# Plan build dependencies in a standalone layer for caching.
FROM base AS planner
ARG BINARY
COPY . .
RUN cargo chef prepare --bin "$BINARY"

# In new layer: build dependencies, copy source code, then build executable.
FROM base AS builder
ARG BINARY
COPY --from=planner /app/recipe.json recipe.json
# RUN cargo chef cook --bin "$BINARY" --release
COPY . .
RUN CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse CARGO_NET_GIT_FETCH_WITH_CLI=true cargo build --bin "$BINARY" --release

# Move binary to /executable, strip it, and verify it is statically linked.
RUN ./get-executable.sh "$BINARY"; strip /executable; ./verify-static-build.sh;

# Copy static binary to minimal image. Note Chainguard's static image
# only has a latest tag, so the image is not pinned to a specific version
# hadolint ignore=DL3007
FROM chainguard/static:latest AS runtime
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

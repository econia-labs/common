# Declare base image and working directory.
FROM econialabs/muslrust-chef:0.1.0 AS base
WORKDIR /app

# Plan build dependencies in a standalone layer for caching.
FROM base AS planner
ARG MEMBER
COPY . .
RUN cargo chef prepare --bin "$MEMBER"

# In new layer: build dependencies, copy source code, then build executable.
FROM base AS builder
ARG MEMBER
COPY --from=planner /app/recipe.json recipe.json
RUN \
    CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG=true \
    RUST_BACKTRACE=full \
    cargo chef cook --bin "$MEMBER" --release
COPY . .
RUN cargo build --bin "$MEMBER" --release

# Move binary to /executable, strip it, and verify it is statically linked.
RUN ./get-executable.sh "$MEMBER"; strip /executable; ./verify-static-build.sh;

# Copy static binary to minimal image. Note Chainguard's static image
# only has a latest tag, so the image is not pinned to a specific version
# hadolint ignore=DL3007
FROM chainguard/static:latest AS runtime
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

# Declare base image and working directory.
FROM econialabs/rust-builder:0.1.0 AS base
WORKDIR /app

# Plan build dependencies in a standalone layer for caching.
FROM base AS planner
ARG MEMBER
COPY . .
RUN cargo chef prepare --bin "$MEMBER"

# In new layer: build Rust dependencies, copy source code, then build executable.
FROM base AS builder
ARG MEMBER
RUN ./install-packages "$BUILDTIME_DEPENDENCIES"
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --bin "$MEMBER" --release
COPY . .
RUN cargo build --bin "$MEMBER" --release

# Move binary to /executable, strip it, and verify it is dynamically linked.
RUN ./get-executable.sh "$MEMBER"; strip /executable; ./verify-dynamic-link.sh;

# Install runtime dependencies, copy executable.
FROM debian:12.6-slim
RUN ./install-packages "$RUNTIME_DEPENDENCIES"
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]
# Declare base image and working directory.
FROM econialabs/rust-builder:0.1.0 AS base
WORKDIR /app

# Plan build dependencies in a standalone layer for caching.
FROM base AS planner
ARG MEMBER
COPY . .
RUN cargo chef prepare --bin "$MEMBER"

# In new layer: install package dependencies, build Rust dependencies,
# copy source code, compile executable, then prepare it for next layer.
FROM base AS builder
ARG MEMBER
RUN ./install-packages "$BUILDTIME_DEPENDENCIES"
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --bin "$MEMBER" --release
COPY . .
RUN cargo build --bin "$MEMBER" --release
RUN ./prepare-executable "$MEMBER" dynamic

# In new layer: install runtime dependencies, copy over executable.
FROM debian:12.6-slim
RUN ./install-packages "$RUNTIME_DEPENDENCIES"
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]
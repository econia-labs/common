# Chainguard image tag, Rust builder version.
ARG TAG=sha256-1e1b7e420a2eb14197aef25917a9e17401caed1806b8d18204a90d7642e1b383
ARG BUILDER_VERSION=0.1.0

FROM econialabs/rust-builder-dynamic:$BUILDER_VERSION AS base
WORKDIR /app

FROM base AS planner
COPY . .
RUN cargo chef prepare

FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner app/recipe.json recipe.json
RUN cargo chef cook --bin "$BIN" --locked --package "$PACKAGE" --release
COPY . .
RUN cargo build --bin "$BIN" --frozen --package "$PACKAGE" --release
# hadolint ignore=DL3059
RUN mv "/app/target/release/$BIN" /executable;

FROM chainguard/glibc-dynamic:$TAG
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

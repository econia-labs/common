# Chainguard image digest (SHA-256), Rust builder version.
ARG DIGEST=c907cf5576de12bb54ac2580a91d0287de55f56bce4ddd66a0edf5ebaba9feed
ARG BUILDER_VERSION=1.1.0

FROM econialabs/rust-builder:$BUILDER_VERSION AS base
WORKDIR /app

FROM base AS planner
ARG BIN
COPY . .
RUN cargo chef prepare --bin "$BIN"

FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner app/recipe.json recipe.json
RUN cargo chef cook --bin "$BIN" --locked --package "$PACKAGE" --release
COPY . .
RUN cargo build --bin "$BIN" --frozen --package "$PACKAGE" --release; \
    mv "/app/target/release/$BIN" /executable;

FROM chainguard/glibc-dynamic@sha256:$DIGEST
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

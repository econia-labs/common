# Chainguard image tag.
ARG TAG=sha256-1e1b7e420a2eb14197aef25917a9e17401caed1806b8d18204a90d7642e1b383

FROM econialabs/rust-builder-dynamic:0.1.0 AS base
WORKDIR /app

FROM base AS planner
ARG BIN
COPY . .
RUN cargo chef prepare --bin "$BIN"
# Delete all but minimum files required to index dependencies, to reduce cache
# invalidation on code changes.
RUN find -type f \! \
    \( -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name 'recipe.json' \) \
    -delete && find . -type d -empty -delete

# Index depenencies.
FROM base as indexer
COPY --from=planner /app .
RUN cargo update --dry-run

FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner /app/recipe.json recipe.json
COPY --from=indexer $CARGO_HOME $CARGO_HOME
RUN cargo chef cook --bin "$BIN" --package "$PACKAGE" --release
COPY . .
RUN cargo build --bin "$BIN" --package "$PACKAGE" --release --offline
RUN mv "$(find /app/target/release/$BIN)" /executable; strip /executable;

FROM chainguard/glibc-dynamic:$TAG
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]
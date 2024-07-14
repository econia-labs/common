# Chainguard image tag.
ARG TAG=sha256-1e1b7e420a2eb14197aef25917a9e17401caed1806b8d18204a90d7642e1b383

FROM econialabs/rust-builder-dynamic:0.1.0 AS base
WORKDIR /app

FROM base AS planner
ARG BIN
COPY . .
RUN cargo chef prepare --bin "$BIN"
# Delete all but minimum files required to build local crate index, to avoid
# invalidating cache of local crate index when code changes.
RUN find -type f \! \
    \( -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name 'recipe.json' \) \
    -delete && find . -type d -empty -delete

# Trigger a dry run update to the lockfile to build a cached local crate index.
FROM base AS indexer
COPY --from=planner /app .
RUN cargo update --dry-run

FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner /app/recipe.json recipe.json
COPY --from=indexer $CARGO_HOME $CARGO_HOME
# Bulid in locked mode, which relies on lockfile and only downloads required
# dependencies.
RUN cargo chef cook --bin "$BIN" --package "$PACKAGE" --release --locked
COPY . .
# Build in frozen mode, which relies on lockfile and is completely offline.
RUN cargo build --bin "$BIN" --package "$PACKAGE" --release --frozen
RUN mv "$(find /app/target/release/$BIN)" /executable; strip /executable;

FROM chainguard/glibc-dynamic:$TAG
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

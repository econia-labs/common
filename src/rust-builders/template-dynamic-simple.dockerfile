# Chainguard image tag.
ARG TAG=sha256-1e1b7e420a2eb14197aef25917a9e17401caed1806b8d18204a90d7642e1b383

FROM econialabs/rust-builder-dynamic:0.1.0 AS base
WORKDIR /app

FROM base AS planner
ARG BIN
COPY . .
# Prepare recipe one directory up to simplify local crate index cache process.
RUN cargo chef prepare --bin "$BIN" --recipe-path ../recipe.json
# Delete everything not required to build local crate index, to avoid
# invalidating local crate index cache on code changes or recipe updates.
RUN find -type f \! \( -name 'Cargo.toml' -o -name 'Cargo.lock' \) -delete && \
    find -type d -empty -delete

# Invoke a dry run lockfile update against the manifest skeleton, thereby
# caching a local crate index.
FROM base AS indexer
COPY --from=planner /app .
RUN cargo update --dry-run

FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner /recipe.json recipe.json
# Copy cached crate index.
COPY --from=indexer $CARGO_HOME $CARGO_HOME
# Build in locked mode to prevent local crate index cache invalidation, thereby
# downloading only the necessary dependencies.
RUN cargo chef cook --bin "$BIN" --locked --package "$PACKAGE" --release
COPY . .
# Build offline solely from cached crate index and downloaded dependencies.
RUN cargo build --bin "$BIN" --frozen --package "$PACKAGE" --release
RUN mv "$(find /app/target/release/$BIN)" /executable;

FROM chainguard/glibc-dynamic:$TAG
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

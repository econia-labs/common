# Chainguard image tag.
ARG TAG=sha256-1e1b7e420a2eb14197aef25917a9e17401caed1806b8d18204a90d7642e1b383

FROM econialabs/rust-builder-dynamic:0.1.0 AS base
WORKDIR /app

FROM base AS planner
COPY . .
RUN cargo chef prepare

# Cache dependencies and local crate index, build offline solely from cache.
FROM base AS builder
ARG BIN PACKAGE
COPY --from=planner app/recipe.json recipe.json
RUN cargo chef cook --bin "$BIN" --locked --package "$PACKAGE" --release
COPY . .
RUN cargo build --bin "$BIN" --frozen --package "$PACKAGE" --release
RUN mv "/app/target/release/$BIN" /executable;

FROM chainguard/glibc-dynamic:$TAG
COPY --chown=nonroot:nonroot --from=builder /executable /executable
ENTRYPOINT ["/executable"]

FROM clux/muslrust:1.79.0-stable as builder
COPY . .
RUN cargo build --bin allowlist --release

FROM chainguard/static:latest as runtime
COPY --from=builder --chown=nonroot:nonroot \
    /volume/target/release/allowlist \
    /app/allowlist
CMD ["/app/allowlist"]

FROM rust:1.79.0-slim-bookworm
RUN cargo install cargo-chef@0.1.67
COPY --chmod=0755 ./scripts /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

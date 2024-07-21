# cspell:word clux
FROM clux/muslrust:1.79.0-stable
RUN cargo install cargo-chef@0.1.67
COPY --chmod=0755 static-builder-scripts /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

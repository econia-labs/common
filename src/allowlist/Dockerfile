FROM rust:1.79-alpine3.20 as builder
WORKDIR /allowlist
COPY . .
RUN apk add 'musl-dev=1.2.5-r0'
RUN cargo build --release

FROM alpine:3.20 as runtime
COPY --from=builder \
    /allowlist/target/release/allowlist \
    /usr/local/bin/allowlist
CMD ["allowlist"]
<!--
cspell:word sadd
cspell:word sismember
cspell:word smembers
-->

# Allowlist

## Design

### Components

`allowlist` combines a Redis in-memory database with an asynchronous REST API.
The server, implemented in Rust, is modeled off a [basic `axum` example] and
adapts features from an [`axum` with Redis example], in particular a
[custom extractor] for a database connection, which is extended in `allowlist`
via a [nested extractor].

### Containerization

Cross-compilation to the `x86_64-unknown-linux-musl` target architecture is
*not* performed in the `allowlist` Dockerfile, so as to enable local builds with
the Docker compose environment. For more on cross-compilation, see
[here][building x86 rust containers from mac silicon],
[here][cross-compiling static rust binaries in docker for raspberry pi], and
[here][`rust-static-builder`].

Per [`muslrust`] best practice recommendations, [`cargo-chef`] is used for image
layer caching, and the final executable is stored in a [`chainguard/static`]
base image (rather than `scratch`) as additionally recommended
[here][`kube.rs` best practices]. This approach yields a final Docker image that
is only 2.5 MB when compiled on an `arm64` machine.

### Deployment automation

## Running a local deployment

```sh
docker compose up
```

Or in detached mode:

```sh
docker compose --detach
```

To stop from detached mode:

```sh
docker compose down
```

## Check if address is allowed

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS | jq
```

## Add address to allowlist

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS -X POST | jq
```

[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[building x86 rust containers from mac silicon]: https://loige.co/building_x86_rust-containers-from-mac-silicon/
[cross-compiling static rust binaries in docker for raspberry pi]: https://jakewharton.com/cross-compiling-static-rust-binaries-in-docker-for-raspberry-pi/
[custom extractor]: https://github.com/tokio-rs/axum/blob/035c8a36b591bb81b8d107c701ac4b14c0230da3/examples/tokio-redis/src/main.rs#L75
[nested extractor]: https://docs.rs/axum/0.7.5/axum/extract/index.html#accessing-other-extractors-in-fromrequest-or-fromrequestparts-implementations
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs
[`cargo-chef`]: https://github.com/LukeMathWalker/cargo-chef
[`chainguard/static`]: https://hub.docker.com/r/chainguard/static
[`kube.rs` best practices]: https://kube.rs/controllers/security/#base-images
[`muslrust`]: https://github.com/clux/muslrust
[`rust-static-builder`]: https://github.com/fornwall/rust-static-builder

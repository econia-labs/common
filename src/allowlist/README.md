<!--
cspell:word sadd
cspell:word sismember
cspell:word smembers
-->

# Allowlist

## Design

`allowlist` combines a Redis in-memory database with an asynchronous REST API.
The server, implemented in Rust, is modeled off a [basic `axum` example] and
adapts features from an [`axum` with Redis example], in particular a
database connection [custom extractor] which is extended here with a
[nested extractor].

The `allowlist` binary leverages the [`mimalloc` crate] as a drop-in
[global allocator] solution, which is required to prevent asynchronous
performance regression for static (standalone) binaries compiled via `musl` (see
[here][supercharging your rust static executables with mimalloc],
[here][testing alternative c memory allocators pt 2: the musl mystery], and
[here][static linking for rust without glibc - scratch image]). Notably, this
approach eliminates the requirement for a Docker build image with a
manually-patched allocator (see [here][`rust-alpine-mimalloc`],
[here][`mimalloc`], and [here][`alpine-mimalloc`]).

Static containerization is performed via the [`muslrust`] image due to its
extensively useful documentation (in particular its examples and
[`mimalloc` commentary]), though notably there are several other comparable
solutions including [`rust-musl-builder`], which contains a useful index of
associated projects.  Cross-compilation to the `x86_64-unknown-linux-musl`
target architecture is *not* performed in the `allowlist` Dockerfile, so as to
enable local builds with the Docker compose environment.

Per [`muslrust`] best practice recommendations, [`cargo-chef`] is used for image
layer caching, and the final executable is stored in a [`chainguard/static`]
image layer (rather than in a `scratch` layer, which is discouraged).

For more about static compilation, see also the
[below references](#supplemental-static-binary-references).

## Running a local deployment

From repository root:

```sh
docker compose --file src/allowlist/compose.yaml up
```

Or in detached mode:

```sh
docker compose --file src/allowlist/compose.yaml up --detach
```

To stop from detached mode:

```sh
docker compose --file src/allowlist/compose.yaml down
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

## Supplemental static binary references

### Blogs

- [Building x86 Rust containers from Mac Silicon]
- [Cross-compiling static Rust binaries in Docker for Raspberry Pi]
- [Docker "FROM scratch" for Rust Applications]
- [How to create small Docker images for Rust]
- [How to Package Rust Applications Into Minimal Docker Containers]
- [Use Multi-Stage Docker Builds For Statically-Linked Rust Binaries]

### Forums

- [How to generate statically linked executables?]
- [Looking for the perfect Dockerfile for Rust]
- [Rust linker fails when using target-feature=+crt-static on nightly]

### Repositories

- [`rust-static-builder`]

### Rust docs

- [Static and dynamic C runtimes]
- [`target-feature`]

[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[building x86 rust containers from mac silicon]: https://loige.co/building_x86_rust-containers-from-mac-silicon/
[cross-compiling static rust binaries in docker for raspberry pi]: https://jakewharton.com/cross-compiling-static-rust-binaries-in-docker-for-raspberry-pi/
[custom extractor]: https://github.com/tokio-rs/axum/blob/035c8a36b591bb81b8d107c701ac4b14c0230da3/examples/tokio-redis/src/main.rs#L75
[docker "from scratch" for rust applications]: https://www.21analytics.ch/blog/docker-from-scratch-for-rust-applications/
[global allocator]: https://doc.rust-lang.org/std/alloc/index.html#the-global_allocator-attribute
[how to create small docker images for rust]: https://kerkour.com/rust-small-docker-image
[how to generate statically linked executables?]: https://stackoverflow.com/questions/31770604
[how to package rust applications into minimal docker containers]: https://alexbrand.dev/post/how-to-package-rust-applications-into-minimal-docker-containers/
[looking for the perfect dockerfile for rust]: https://www.reddit.com/r/rust/comments/16bswvl/comment/jzh6enu/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
[nested extractor]: https://docs.rs/axum/0.7.5/axum/extract/index.html#accessing-other-extractors-in-fromrequest-or-fromrequestparts-implementations
[rust linker fails when using target-feature=+crt-static on nightly]: https://stackoverflow.com/questions/76604929
[static and dynamic c runtimes]: https://doc.rust-lang.org/reference/linkage.html#static-and-dynamic-c-runtimes
[static linking for rust without glibc - scratch image]: https://users.rust-lang.org/t/static-linking-for-rust-without-glibc-scratch-image/112279/5
[supercharging your rust static executables with mimalloc]: https://www.tweag.io/blog/2023-08-10-rust-static-link-with-mimalloc/
[testing alternative c memory allocators pt 2: the musl mystery]: https://www.linkedin.com/pulse/testing-alternative-c-memory-allocators-pt-2-musl-mystery-gomes/
[use multi-stage docker builds for statically-linked rust binaries]: https://dev.to/deciduously/use-multi-stage-docker-builds-for-statically-linked-rust-binaries-3jgd
[`alpine-mimalloc`]: https://github.com/emerzon/alpine-mimalloc
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs
[`cargo-chef`]: https://github.com/LukeMathWalker/cargo-chef
[`chainguard/static`]: https://hub.docker.com/r/chainguard/static
[`mimalloc`]: https://github.com/marvin-hansen/mimalloc
[`mimalloc` commentary]: https://github.com/clux/muslrust/issues/142
[`mimalloc` crate]: https://docs.rs/mimalloc/latest/mimalloc/
[`muslrust`]: https://github.com/clux/muslrust
[`rust-alpine-mimalloc`]: https://github.com/tweag/rust-alpine-mimalloc
[`rust-musl-builder`]: https://github.com/emk/rust-musl-builder
[`rust-static-builder`]: https://github.com/fornwall/rust-static-builder
[`target-feature`]: https://doc.rust-lang.org/rustc/codegen-options/index.html#target-feature

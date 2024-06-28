<!--
cspell:word sadd
cspell:word sismember
cspell:word smembers
-->

# Allowlist

## Start local deployment

```sh
docker compose up --detach
```

## Stop local deployment

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

## References

### Axum

- [Basic `axum` example]
- [`axum` with Redis example]

### Static linking

#### Blogs

- [Building x86 Rust containers from Mac Silicon]
- [Cross-compiling static Rust binaries in Docker for Raspberry Pi]
- [Docker "FROM scratch" for Rust Applications]
- [How to create small Docker images for Rust]
- [How to Package Rust Applications Into Minimal Docker Containers]
- [Static linking for rust without glibc - scratch image]
- [SUPERCHARGING YOUR RUST STATIC EXECUTABLES WITH MIMALLOC]
- [Testing Alternative C Memory Allocators Pt 2: The MUSL mystery]
- [Use Multi-Stage Docker Builds For Statically-Linked Rust Binaries]

#### Forums

- [How to generate statically linked executables?]
- [Looking for the perfect Dockerfile for Rust]
- [Rust linker fails when using target-feature=+crt-static on nightly]
- [static linking for rust without glibc - scratch image]

#### Rust docs

- [Static and dynamic C runtimes]
- [`target-feature`]

#### Repositories

- [`alpine-mimalloc`]
- [`mimalloc`]
- [`muslrust`]
- [`rust-alpine-mimalloc`]
- [`rust-static-builder`]

[`muslrust`]: https://github.com/clux/muslrust
[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[building x86 rust containers from mac silicon]: https://loige.co/building_x86_rust-containers-from-mac-silicon/
[cross-compiling static rust binaries in docker for raspberry pi]: https://jakewharton.com/cross-compiling-static-rust-binaries-in-docker-for-raspberry-pi/
[docker "from scratch" for rust applications]: https://www.21analytics.ch/blog/docker-from-scratch-for-rust-applications/
[how to create small docker images for rust]: https://kerkour.com/rust-small-docker-image
[how to generate statically linked executables?]: https://stackoverflow.com/questions/31770604
[how to package rust applications into minimal docker containers]: https://alexbrand.dev/post/how-to-package-rust-applications-into-minimal-docker-containers/
[looking for the perfect dockerfile for rust]: https://www.reddit.com/r/rust/comments/16bswvl/comment/jzh6enu/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
[rust linker fails when using target-feature=+crt-static on nightly]: https://stackoverflow.com/questions/76604929
[static and dynamic c runtimes]: https://doc.rust-lang.org/reference/linkage.html#static-and-dynamic-c-runtimes
[static linking for rust without glibc - scratch image]: https://users.rust-lang.org/t/static-linking-for-rust-without-glibc-scratch-image/112279
[supercharging your rust static executables with mimalloc]: https://www.tweag.io/blog/2023-08-10-rust-static-link-with-mimalloc/
[testing alternative c memory allocators pt 2: the musl mystery]: https://www.linkedin.com/pulse/testing-alternative-c-memory-allocators-pt-2-musl-mystery-gomes/
[use multi-stage docker builds for statically-linked rust binaries]: https://dev.to/deciduously/use-multi-stage-docker-builds-for-statically-linked-rust-binaries-3jgd
[`alpine-mimalloc`]: https://github.com/emerzon/alpine-mimalloc
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs
[`mimalloc`]: https://github.com/marvin-hansen/mimalloc
[`rust-alpine-mimalloc`]: https://github.com/tweag/rust-alpine-mimalloc
[`rust-static-builder`]: https://github.com/fornwall/rust-static-builder
[`target-feature`]: https://doc.rust-lang.org/rustc/codegen-options/index.html#target-feature

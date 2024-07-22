# `rust-builder`

## General

The [`rust-builder` Dockerfile] describes an image that can be used
to efficiently containerize standalone Rust applications. It is pinned to a
lightweight Rust image version, and comes with [`cargo-chef`] pre-installed.
The `rust-builder` image also comes with `git` since it sets
[`CARGO_NET_GIT_FETCH_WITH_CLI`] to `true` as a
[solution to `cargo build` memory issues] originally observed during
[multi-platform image builds] (specifically the `cargo chef cook` command).

See [`template.Dockerfile`], which can be used to containerize any binary
inside the minimal [`glibc-dynamic`] base image. For example, to containerize
and the `hello-world` program in the `rust_builder` [Cargo package], run from
the repository root:

```sh
docker build \
    --build-arg BIN=hello-world \
    --build-arg BUILDER_VERSION="latest" \
    --build-arg PACKAGE=rust_builder \
    --file src/rust-builder/template.Dockerfile \
    --tag rust-builder/hello-world \
    src
```

Note that the first time you run this command, the `cargo chef cook` command
will need to download the `aptos-core` git dependency in order to create a local
[crate index] cache for the `cloud-infra` [Cargo workspace], but subsequent
builds will be able to reuse the cache. To run the container:

```sh
docker run rust-builder/hello-world
```

To observe the caching in action, change [`src/hello_world.rs`] to say
`Hello, builder!` and save, then run the above commands again, noting that a
cache miss has only been triggered on the final `cargo build` command, as if you
had already [refreshed the local index via `cargo update --dry-run`] and
compiled all dependencies via [`cargo build --dependencies-only` (proposed)].

## Platform support

The [`rust-builder` Docker Hub image] is built via the
[`push-rust-builder.yaml`] [GitHub action], and supports only `arm64` and
`amd64` architectures specified per the `DOCKER_IMAGE_PLATFORMS`
[GitHub organization variable] for Econia Labs. Notably, these image
architectures should be sufficient to support most Linux and Mac machines.

## About linking

Note that the `rust-builder` is designed for use with dynamic linking against
`glibc`, hence the [`glibc-dynamic`] base image in [`template.Dockerfile`]. This
approach ensures minimal container sizes with maximal portability, since there
is no need to specify any compiler or linker configurations. For the example
above, the final Docker image should be less than 10 MB:

```sh
docker images rust-builder/hello-world
```

If you want to containerize a Rust application that has additional non-Rust
dependencies beyond `glibc`, you will probably want to use a final image like
`debian/bookworm-slim` that has additional runtime dependencies installed via
[`apt-get` best practices]. Note that this will require a custom Dockerfile to
install your specific runtime dependencies.

While it is possible to statically link Rust executables via projects like
[`muslrust`] for even smaller Docker builds, this approach is discouraged
because of portability concerns. In short, `muslrust` can exhibit performance
degradations in asynchronous environments when compared against `glibc`, and
while there are [drop-in allocators] that can be used to improve `muslrust`
performance, they do not reliably compile on standard platforms (namely, through
[GitHub action] builds or even on an `arm64` Mac). Moreover, verifying that a
binary has been linked requires a call to `lld`, which can print out different
messages based on the platform.

[`apt-get` best practices]: https://docs.docker.com/build/building/best-practices/#apt-get
[cargo package]: https://doc.rust-lang.org/cargo/guide/project-layout.html
[cargo workspace]: https://doc.rust-lang.org/cargo/reference/workspaces.html
[crate index]: https://github.com/rust-lang/cargo/issues/3377
[drop-in allocators]: https://github.com/clux/muslrust?tab=readme-ov-file#allocator-performance
[github action]: https://docs.docker.com/build/ci/github-actions/
[github organization variable]: https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-an-organization
[multi-platform image builds]: https://docs.docker.com/build/ci/github-actions/multi-platform/
[refreshed the local index via `cargo update --dry-run`]: https://github.com/serayuzgur/crates/issues/81#issuecomment-634037996
[solution to `cargo build` memory issues]: https://github.com/rust-lang/cargo/issues/10781#issuecomment-1351670409
[`cargo build --dependencies-only` (proposed)]: https://github.com/rust-lang/cargo/issues/2644
[`cargo-chef`]: https://github.com/LukeMathWalker/cargo-chef
[`cargo_net_git_fetch_with_cli`]: https://doc.rust-lang.org/cargo/reference/config.html#netgit-fetch-with-cli
[`glibc-dynamic`]: https://images.chainguard.dev/directory/image/glibc-dynamic/overview
[`muslrust`]: https://github.com/clux/muslrust
[`push-rust-builder.yaml`]: ../../.github/workflows/push-rust-builder.yaml
[`rust-builder` docker hub image]: https://hub.docker.com/repository/docker/econialabs/rust-builder/tags
[`rust-builder` dockerfile]: ./Dockerfile
[`src/hello_world.rs`]: ./src/hello_world.rs
[`template.dockerfile`]: ./template.Dockerfile

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
    --tag hello-world \
    src
```

Note that the first time you run this command, the `cargo chef cook` command
will need to download the `aptos-core` git dependency in order to create a local
crate index cache for the `cloud-infra` [Cargo workspace], but subsequent builds
will be able to reuse the cache. To run the container:

```sh
docker run hello-world
```

To observe the caching in action, change [`src/hello_world.rs`] to say
`Hello, builder!` then run the above commands again, noting that a cache miss
has only been triggered on the final `cargo build` command.

## Platform support

The [`rust-builder` Docker Hub image] is built via the
[`push-rust-builder.yaml`] [GitHub action], and supports only `arm64` and
`amd64` architectures specified per the `DOCKER_IMAGE_PLATFORMS`
[GitHub organization variable] for Econia Labs. Notably, these image
architectures should be sufficient to support most Linux and Mac machines.

[cargo package]: https://doc.rust-lang.org/cargo/guide/project-layout.html
[cargo workspace]: https://doc.rust-lang.org/cargo/reference/workspaces.html
[github action]: https://docs.docker.com/build/ci/github-actions/
[github organization variable]: https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-an-organization
[multi-platform image builds]: https://docs.docker.com/build/ci/github-actions/multi-platform/
[solution to `cargo build` memory issues]: https://github.com/rust-lang/cargo/issues/10781#issuecomment-1351670409
[`cargo-chef`]: https://github.com/LukeMathWalker/cargo-chef
[`cargo_net_git_fetch_with_cli`]: https://doc.rust-lang.org/cargo/reference/config.html#netgit-fetch-with-cli
[`glibc-dynamic`]: https://images.chainguard.dev/directory/image/glibc-dynamic/overview
[`push-rust-builder.yaml`]: ../../.github/workflows/push-rust-builder.yaml
[`rust-builder` docker hub image]: https://hub.docker.com/repository/docker/econialabs/rust-builder/tags
[`rust-builder` dockerfile]: ./Dockerfile
[`src/hello_world.rs`]: ./src/hello_world.rs
[`template.dockerfile`]: ./template.Dockerfile

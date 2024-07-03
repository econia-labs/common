# `muslrust-chef`

This Docker image combines [`muslrust`], [`cargo-chef`], and custom shell
scripts to enable cached, multi-platform compilation of static Rust binaries.
For an example, see the [`allowlist` Dockerfile].

## Rust static compilation

Static binaries may be compiled in rust by combining the `musl` C library with a
multi-stage Docker build. Notably, for Rust applications without any non-Rust
dependencies, this approach enables the compilation of a standalone executable
such that the resulting Docker image is only as large as the target Rust binary
itself. For relevant blog posts on this topic, see
[here][how to create small docker images for rust],
[here][how to package rust applications into minimal docker containers],
[here][use multi-stage docker builds for statically-linked rust binaries], and
[here][docker "from scratch" for rust applications]. For forum discussions, see
[here][looking for the perfect dockerfile for rust],
[here][how to generate statically linked executables?], and
[here][rust linker fails when using target-feature=+crt-static on nightly]. For
relevant Rust documentation see [here][static and dynamic c runtimes] and
[here][`target-feature`].

While not required, it is recommended that static binaries leverage the
[`mimalloc` crate] as a drop-in [global allocator] solution, which is required
to prevent asynchronous performance regression when statically compiling against
`musl`, as detailed
[here][supercharging your rust static executables with mimalloc],
[here][testing alternative c memory allocators pt 2: the musl mystery], and
[here][static linking for rust without glibc - scratch image]. Notably, this
approach eliminates the requirement of a Docker build image with a
manually-patched allocator, as proposed [here][`rust-alpine-mimalloc`],
[here][`mimalloc`], and [here][`alpine-mimalloc`]. For a drop-in
[`mimalloc` crate] example, see the [`allowlist` source].

## Best practices

This Docker image performs static containerization via the [`muslrust`] image
due to its extensive instructive documentation (in particular its examples and
[`mimalloc` commentary]), though notably there are several other comparable
solutions including [`rust-musl-builder`], which contains a useful index of
associated projects. Note too that [`cargo-chef` recommends `muslrust` for
static compilation][`cargo-chef` recommends `muslrust` for static compilation].

Per [`muslrust`] best practice recommendations, as reflected in the
[`allowlist` Dockerfile] example, [`cargo-chef`] is suggested for
image layer caching, and it is suggested that the final executable be stored in
a [`chainguard/static`] base image (rather than `scratch`) as additionally
recommended [here][`kube.rs` best practices]. In the case of the
[`allowlist` Dockerfile], This approach yields a final Docker image that is only
several MB when compiled on an `arm64` machine.

## Automation

See [`build-push-muslrust-chef.yaml`] for an example of
[Docker Hub with GitHub Actions] that supports cross-compilation with
[layer caching on GitHub Actions], yielding a [multi-platform image]. Since
[`muslrust`] only provides `linux/arm64` and `linux/amd64` base image support,
`muslrust-chef` is only compiled for these two architectures, via the
`MUSLRUST_PLATFORMS` [GitHub organization variable].

`muslrust-chef` sets the [`CARGO_NET_GIT_FETCH_WITH_CLI`] environment variable
to `true` to prevent cross-compilation memory issues (as suggested
[here][qemu memory use]) that were originally incurred whe updating the
`aptos-core` Rust index during build time. While investigating this fix, it was
noted that the [`CARGO_REGISTRIES_CRATES_IO_PROTOCOL`] environment variable had
solved similar issues for other users, even though it ended up not being
necessary in the present implementation. For more on this topic, which may prove
useful in potential future fixes, see
[here][rust crates index issue],
[here][cargo build uses too much cpu],
[here][cargo registry cache clear suggestion],
[here][cargo-chef sparse issue 136],
[here][cargo-chef sparse issue 107],
[here][cargo-chef add unstable flags],
[here][arm64 memory build issue], and
[here][cargo build clear cache fix].

[arm64 memory build issue]: https://github.com/keenanjohnson/ros2_rust_workspace/issues/21
[cargo build clear cache fix]: https://github.com/rust-lang/cargo/issues/5101
[cargo build uses too much cpu]: https://github.com/rust-lang/cargo/issues/4346
[cargo registry cache clear suggestion]: https://github.com/rust-lang/cargo/issues/7662#issuecomment-561917271
[cargo-chef add unstable flags]: https://github.com/LukeMathWalker/cargo-chef/pull/137
[cargo-chef sparse issue 107]: https://github.com/LukeMathWalker/cargo-chef/issues/107
[cargo-chef sparse issue 136]: https://github.com/LukeMathWalker/cargo-chef/issues/136
[docker "from scratch" for rust applications]: https://www.21analytics.ch/blog/docker-from-scratch-for-rust-applications/
[docker hub with github actions]: https://docs.docker.com/build/ci/github-actions/
[github organization variable]: https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-an-organization
[global allocator]: https://doc.rust-lang.org/std/alloc/index.html#the-global_allocator-attribute
[how to create small docker images for rust]: https://kerkour.com/rust-small-docker-image
[how to generate statically linked executables?]: https://stackoverflow.com/a/31778003
[how to package rust applications into minimal docker containers]: https://alexbrand.dev/post/how-to-package-rust-applications-into-minimal-docker-containers/
[layer caching on github actions]: https://docs.docker.com/build/ci/github-actions/cache/#github-cache
[looking for the perfect dockerfile for rust]: https://www.reddit.com/r/rust/comments/16bswvl/comment/jzh6enu/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
[multi-platform image]: https://docs.docker.com/build/ci/github-actions/multi-platform/
[qemu memory use]: https://users.rust-lang.org/t/cargo-uses-too-much-memory-being-run-in-qemu/76531/5
[rust crates index issue]: https://github.com/rust-lang/cargo/issues/10781
[rust linker fails when using target-feature=+crt-static on nightly]: https://stackoverflow.com/questions/76604929
[static and dynamic c runtimes]: https://doc.rust-lang.org/reference/linkage.html#static-and-dynamic-c-runtimes
[static linking for rust without glibc - scratch image]: https://users.rust-lang.org/t/static-linking-for-rust-without-glibc-scratch-image/112279/5
[supercharging your rust static executables with mimalloc]: https://www.tweag.io/blog/2023-08-10-rust-static-link-with-mimalloc/
[testing alternative c memory allocators pt 2: the musl mystery]: https://www.linkedin.com/pulse/testing-alternative-c-memory-allocators-pt-2-musl-mystery-gomes/
[use multi-stage docker builds for statically-linked rust binaries]: https://dev.to/deciduously/use-multi-stage-docker-builds-for-statically-linked-rust-binaries-3jgd
[`allowlist` dockerfile]: ../allowlist/Dockerfile
[`allowlist` source]: ../allowlist/src/main.rs
[`alpine-mimalloc`]: https://github.com/emerzon/alpine-mimalloc
[`build-push-muslrust-chef.yaml`]: ../../.github/workflows/build-push-muslrust-chef.yaml
[`cargo-chef`]: https://github.com/LukeMathWalker/cargo-chef
[`cargo-chef` recommends `muslrust` for static compilation]: https://github.com/LukeMathWalker/cargo-chef?tab=readme-ov-file#running-the-binary-in-alpine
[`cargo_net_git_fetch_with_cli`]: https://doc.rust-lang.org/cargo/reference/config.html#netgit-fetch-with-cli
[`cargo_registries_crates_io_protocol`]: https://blog.rust-lang.org/inside-rust/2023/01/30/cargo-sparse-protocol.html
[`chainguard/static`]: https://hub.docker.com/r/chainguard/static
[`kube.rs` best practices]: https://kube.rs/controllers/security/#base-images
[`mimalloc`]: https://github.com/marvin-hansen/mimalloc
[`mimalloc` commentary]: https://github.com/clux/muslrust/issues/142
[`mimalloc` crate]: https://docs.rs/mimalloc/latest/mimalloc/
[`muslrust`]: https://github.com/clux/muslrust
[`rust-alpine-mimalloc`]: https://github.com/tweag/rust-alpine-mimalloc
[`rust-musl-builder`]: https://github.com/emk/rust-musl-builder
[`target-feature`]: https://doc.rust-lang.org/rustc/codegen-options/index.html#target-feature

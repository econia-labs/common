<!--
cspell:word aarch
cspell:word toplevel
cspell:word Macbooks
-->

# Objective

The Aptos CLI is available for various platforms and architectures as a
standalone executable; however, there isn't a ready-to-use Docker image for the
`aarch64` processor architecture (labeled as `linux/arm64/v8` in Docker).

This architecture is particularly significant, as it's used in the ARM-based
Apple silicon found in newer Macbooks.

The image built from this Dockerfile serves to address this gap and provide a
solution for users working with these systems.

It builds an image of the `aptos` CLI for `linux/arm64` and `linux/amd64`, with
the CLI version corresponding directly to the Docker image tag:

```Dockerfile
# Uses the aptos CLI, version 6.0.2
FROM econialabs/aptos-cli:6.0.2

RUN aptos --version
# > aptos 6.0.2
```

## Building the image and pushing it to the `econialabs` Docker Hub registry

To build a Docker image with a specific version of the Aptos CLI, simply push
the corresponding version tag to GitHub to trigger the GitHub workflow that
builds the image in CI:

```shell
git tag aptos-cli-vX.Y.Z
```

This will trigger the GitHub `push-aptos-cli.yaml` workflow to build the `aptos`
CLI Docker image and subsequently push it to the `econialabs` Dockerhub
repository as `econialabs/aptos-cli:X.Y.Z`.

## Triggering the workflow manually

The action is also set to trigger manually on `workflow_dispatch`.

You will be prompted to input the version, which will work with both of the
following formats:

`cli_version: vX.Y.Z`

or

`cli_version: X.Y.Z`

Since the action strips the `v` when parsing the `ARG CLI_VERSION` value.

## Multi-architecture support

Currently the GitHub action triggers builds for `arm64` and `amd64`.

## Building it yourself locally

If you'd like to build the image yourself, you can simply pass the CLI version
as a `build-arg`.

A simple `bash` script for this process might be something like:

```bash
#!/bin/bash

# From the root of this repository.
git_root=$(git rev-parse --show-toplevel)

username=YOUR_DOCKERHUB_USERNAME
version=v6.0.2

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg GIT_TAG=aptos-cli-$version \
  -t $username/aptos-cli:$version \
  -f $git_root/src/aptos-cli/Dockerfile \
  --push \
  .
```

## Resource consumption

Since the `aptos` binary has so many dependencies, compilation may fail due to
resource exhaustion unless adequate measures are taken.

If you are building locally then you should be able to prevent failure by simply
increasing your [Docker Desktop resources], in particular `CPU limit` and
`Memory limit`.

Alternatively, you can pass [`CARGO_BUILD_JOBS`] as a `build-arg` to limit the
number of parallel compilation processes.

[docker desktop resources]: https://docs.docker.com/desktop/settings-and-maintenance/settings/#advanced
[`cargo_build_jobs`]: https://doc.rust-lang.org/cargo/reference/environment-variables.html#configuration-environment-variables

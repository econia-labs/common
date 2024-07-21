# `rust-builder`

## Build and run dynamic example

```sh
docker build \
    --build-arg BIN=hello-world-dynamic \
    --build-arg BUILDER_VERSION="0.1.0" \
    --build-arg PACKAGE=rust_builders \
    --file src/rust-builders/Dockerfile \
    --tag hello-world \
    src
docker run hello-world-dynamic
```

```sh
docker run hello-world-dynamic
```

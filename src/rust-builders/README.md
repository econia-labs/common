# `rust-builders`

## Build and run dynamic example

```sh
docker build \
    --build-arg BIN=hello-world-dynamic \
    --build-arg PACKAGE=hello-world-dynamic \
    --file src/rust-builders/template-dynamic-simple.dockerfile \
    --tag template-dynamic-simple \
    src
```

```sh
docker run template-dynamic-simple
```

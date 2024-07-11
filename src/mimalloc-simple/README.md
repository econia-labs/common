# `mimalloc-simple`

A simple stub package for testing cross-compilation with `mimalloc`. From
repository root:

```sh
docker build \
    --build-arg MEMBER=mimalloc-simple \
    --file src/muslrust-chef/member-template.Dockerfile \
    --tag mimalloc-simple \
    src
docker run mimalloc-simple
```
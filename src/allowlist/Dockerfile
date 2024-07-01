# cspell:word chainguard
# cspell:word clux
# cspell:word hadolint
# cspell:word muslrust
# cspell:word nonroot

# Declare minimal workspace layout relative to repository root.
ARG CARGO_WORKSPACE_DIR=src
ARG BIN_NAME=allowlist
ARG BIN_DIR=$CARGO_WORKSPACE_DIR/$BIN_NAME

# Initialize planning layer.
FROM clux/muslrust:1.79.0-stable AS planner
RUN cargo install cargo-chef@0.1.67

# Replicate minimal workspace layout.
ARG BIN_DIR BIN_NAME CARGO_WORKSPACE_DIR
WORKDIR /
COPY $CARGO_WORKSPACE_DIR/Cargo.toml .
COPY $BIN_DIR/Cargo.toml ./$BIN_NAME/
COPY $BIN_DIR/src ./$BIN_NAME/src

# Prepare build dependency recipe.
RUN cargo chef prepare --bin "$BIN_NAME"

# Compile and cache build dependencies in a separate layer.
FROM clux/muslrust:1.79.0-stable AS cacher
RUN cargo install cargo-chef@0.1.67
WORKDIR /
COPY --from=planner /recipe.json recipe.json
ARG BIN_NAME
RUN cargo chef cook --bin $BIN_NAME --release

# Start another layer to build from cached dependencies.
FROM clux/muslrust:1.79.0-stable AS builder
WORKDIR /
COPY --from=cacher /target target
COPY --from=cacher /root/.cargo /root/.cargo

# Replicate minimal workspace layout.
WORKDIR /
ARG BIN_DIR BIN_NAME CARGO_WORKSPACE_DIR
COPY $CARGO_WORKSPACE_DIR/Cargo.toml .
COPY $BIN_DIR/Cargo.toml ./$BIN_NAME/
COPY $BIN_DIR/src ./$BIN_NAME/src

# Build target binary, then move it to a predictable location by removing it
# from the release directory named after the build architecture. Then strip it.
RUN cargo build --bin "$BIN_NAME" --release
RUN mv "$(find target/*/release/"$BIN_NAME")" target/"$BIN_NAME"
RUN strip target/"$BIN_NAME"

# When ldd is passed a path to a statically linked binary, it prints a message
# to stderr indicating that the binary is statically linked, then exits with an
# error. On arm64 the error message is "not a dynamic executable", while on
# amd64 (x86_64) the error message is "statically linked" (at least as
# observed during multi-platform builds with GitHub actions). Hence redirect
# stderr to stdout, and store the resulting message. Then grep for either of
# the valid messages to check that the binary has been statically linked, and
# do a logical OR of the two grep commands and negate the result. Finally, use
# the result of the negation to determine whether to exit with a nonzero status
# code, causing the build to fail.
# hadolint ignore=DL4006,SC2086
RUN MSG="$(ldd target/"$BIN_NAME" 2>&1)"; if ! ( \
    ( echo $MSG | grep 'not a dynamic executable' ) || \
    ( echo $MSG | grep 'statically linked' ); \
    ); then echo "failed static link check"; exit 1; fi

# Copy the static binary to a minimal image. Note Chainguard's static image
# only has a latest tag, so the image is not pinned to a specific version
# hadolint ignore=DL3007
FROM chainguard/static:latest AS runtime
ARG BIN_NAME
COPY --chown=nonroot:nonroot --from=builder /target/$BIN_NAME /executable
ENTRYPOINT ["/executable"]

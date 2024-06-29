# Declare minimal workspace layout relative to repository root.
ARG CARGO_WORKSPACE_DIR=src
ARG BIN_NAME=allowlist
ARG BIN_DIR=$CARGO_WORKSPACE_DIR/$BIN_NAME

# Initialize planning layer.
FROM clux/muslrust:1.79.0-stable as planner
RUN cargo install cargo-chef@0.1.67

# Replicate minimal workspace layout.
ARG BIN_DIR BIN_NAME CARGO_WORKSPACE_DIR
COPY $CARGO_WORKSPACE_DIR/Cargo.toml .
COPY $BIN_DIR/Cargo.toml ./$BIN_NAME/
COPY $BIN_DIR/src ./$BIN_NAME/src

# Prepare build dependency recipe.
RUN cargo chef prepare --bin $BIN_NAME

# Compile and cache build dependencies in a separate layer.
FROM clux/muslrust:1.79.0-stable as cacher
RUN cargo install cargo-chef@0.1.67
COPY --from=planner /volume/recipe.json recipe.json
ARG BIN_NAME
RUN cargo chef cook --bin $BIN_NAME --release

# Start another layer to build from cached dependencies.
FROM clux/muslrust:1.79.0-stable as builder
COPY --from=cacher /volume/target target
COPY --from=cacher /root/.cargo /root/.cargo

# Replicate minimal workspace layout.
ARG BIN_DIR BIN_NAME CARGO_WORKSPACE_DIR
COPY $CARGO_WORKSPACE_DIR/Cargo.toml .
COPY $BIN_DIR/Cargo.toml ./$BIN_NAME/
COPY $BIN_DIR/src ./$BIN_NAME/src

# Build target binary, then move it to a predictable location by removing it
# from the release directory named after the build architecture.
RUN cargo build --bin $BIN_NAME --release
RUN mv $(find target/*/release/$BIN_NAME) target/$BIN_NAME

# When `ldd` is run on a statically linked binary, it exits with a nonzero
# status code and prints "not a dynamic executable" to stderr. Hence redirect
# stderr to stdout, then grep for the string "not a dynamic executable" to
# check that the library has been statically linked. Negate the output of the
# grep command, such that if there is no match for the expected message, the
# command will exit with a nonzero status code, causing the build to fail.
RUN if ! echo $(ldd target/allowlist 2>&1) | grep 'not a dynamic executable'; \
    then echo "failed static link check"; exit 1; fi

#RUN if echo $(ldd target/$BIN_NAME) | grep -q 'not a dynamic executable'; then exit 1; fi
#RUN if echo $(ldd allowlist) | grep -q 'not a dynnamic executable'; then exit 1; fi

## Copy the static binary to a minimal image.
#FROM chainguard/static:latest as runtime
#ARG BIN_NAME
#COPY --chown=nonroot:nonroot --from=builder \
#/volume/target/$BIN_NAME /executable
#ENTRYPOINT ["/executable"]

# cspell:word clux
# cspell:word muslrust
FROM clux/muslrust:1.79.0-stable AS planner

RUN cargo install cargo-chef@0.1.67

# Relative to repository root.
ARG SRC_WORKSPACE_DIR=src
ARG MUSLRUST_CHEF_DIR=$SRC_WORKSPACE_DIR/muslrust-chef
ARG SCRIPTS_DIR=$MUSLRUST_CHEF_DIR/scripts

WORKDIR /
COPY SCRIPTS_DIR .

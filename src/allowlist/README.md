# Allowlist

## Design

### Components

`allowlist` combines a Redis in-memory database with an asynchronous REST API.
The server, implemented in Rust, is modeled off a [basic `axum` example] and
adapts features from an [`axum` with Redis example], in particular a
[custom extractor] for a database connection, which is extended in `allowlist`
via a [nested extractor]. The server also implements `CTRL+C` and `SIGTERM`
signal handling, modeled off an [`axum` graceful shutdown example], to comply
with [AWS container best practices].

### Containerization

`allowlist` is containerized via the [template Dockerfile] for [`rust-builder`]
and published to the [`allowlist` Docker Hub image] via [`push-allowlist.yaml`].
You can run a local deployment using [Docker compose].

### CloudFormation

A cloud-based version of `allowlist` can be deployed on [AWS CloudFormation] via
the [stack template] and an associated [Git sync stack deployment file] from
[`cloud-formation`].

## Running a local deployment

From repository root:

```sh
docker compose --file src/allowlist/compose.yaml up
```

Or in detached mode:

```sh
docker compose --file src/allowlist/compose.yaml up --detach
```

To stop from detached mode:

```sh
docker compose --file src/allowlist/compose.yaml down
```

## Querying a local deployment

To run the below commands, you'll need `curl` and `jq` on your machine.

### Check if address is allowed

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS | jq
```

### Add address to allowlist

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS -X POST | jq
```

### Observe automatic address sanitation

```sh
REQUESTED_ADDRESS=0x00000123
curl localhost:3000/$REQUESTED_ADDRESS -X POST | jq
```

## Querying the AWS deployment

### AWS CLI dependency

This guide assumes you have used the [`aws configure sso` wizard] to set up an
[`AWS_PROFILE`] named `default`, and that you are logged in via `aws sso login`.

### Get endpoint URL

Set the stack name, for example `allowlist-dev`:

```sh
STACK_NAME=allowlist-dev
```

Get the endpoint URL:

```sh
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
  --output text
)
echo $API_ENDPOINT
```

### Check if address is allowed

```sh
REQUESTED_ADDRESS=0x123
curl $API_ENDPOINT/$REQUESTED_ADDRESS | jq
```

### Add address to allowlist

Assuming your profile is named `default`:

```sh
AWS_PROFILE=default
```

Get profile metadata:

```sh
ACCOUNT_ID=$(aws configure get profile.$AWS_PROFILE.sso_account_id)
REGION=$(aws configure get profile.$AWS_PROFILE.region)
ROLE_NAME=$(aws configure get profile.$AWS_PROFILE.sso_role_name)
echo $ACCOUNT_ID
echo $REGION
echo $ROLE_NAME
```

Generate credentials that you'll need to authenticate the request:

To add an address to the allowlist, you need to authenticate the `POST` request
using AWS Signature Version 4. First you'll need to generate temporary
credentials that you can use the sign the request:

[aws cloudformation]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
[aws container best practices]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-considerations.html
[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[custom extractor]: https://github.com/tokio-rs/axum/blob/035c8a36b591bb81b8d107c701ac4b14c0230da3/examples/tokio-redis/src/main.rs#L75
[docker compose]: https://docs.docker.com/compose/
[git sync stack deployment file]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/git-sync-concepts-terms.html#git-sync-concepts-terms-depoyment-file
[nested extractor]: https://docs.rs/axum/0.7.5/axum/extract/index.html#accessing-other-extractors-in-fromrequest-or-fromrequestparts-implementations
[stack template]: ./cloud-formation/allowlist.cfn.yaml
[template dockerfile]: ../rust-builder/template.Dockerfile
[`allowlist` docker hub image]: https://hub.docker.com/repository/docker/econialabs/allowlist/tags
[`aws configure sso` wizard]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html#cli-configure-sso-configure
[`aws_profile`]: https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-files.html#cli-configure-files-using-profiles
[`axum` graceful shutdown example]: https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs
[`cloud-formation`]: ./cloud-formation
[`push-allowlist.yaml`]: ../../.github/workflows/push-allowlist.yaml
[`rust-builder`]: ../rust-builder/README.md

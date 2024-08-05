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

To interact with the AWS-deployed `allowlist` server, you'll need the API
endpoint URL, which is provided as an output of the CloudFormation stack. You
can retrieve it from the AWS Console or using the AWS CLI.

### Retrieve the API endpoint

Set the stack name, for example `allowlist-dev`:

```sh
STACK_NAME=allowlist-dev
```

Set the deployment region, for example `us-east-2`:

```sh
REGION=us-east-2
```

Using the AWS CLI:

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
curl $API_ENDPOINT$REQUESTED_ADDRESS | jq
```

### Add address to allowlist

To add an address to the allowlist, you need to authenticate the `POST` request
using AWS Signature Version 4. First you'll need to generate temporary
credentials that you can use the sign the request:

```sh
CREDENTIALS=$(aws sts get-session-token \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)
ACCESS_KEY=$(echo $CREDENTIALS | cut -d' ' -f1)
SECRET_KEY=$(echo $CREDENTIALS | cut -d' ' -f2)
SESSION_TOKEN=$(echo $CREDENTIALS | cut -d' ' -f3)
```

Note: Ensure you have the necessary IAM permissions to generate temporary
credentials and invoke the API for POST requests. The role or user you're using
should have permissions to call sts:GetSessionToken and execute-api:Invoke on
your API's resource.

Then you can add an address:
```sh
REQUESTED_ADDRESS=0x123
curl -X POST $API_ENDPOINT$REQUESTED_ADDRESS \
  -H "X-Amz-Security-Token: $SESSION_TOKEN" \
  -H "$(aws sigv4 presign-url \
        --method POST \
        --url $API_ENDPOINT$REQUESTED_ADDRESS \
        --region $REGION \
        --service execute-api \
        --access-key $ACCESS_KEY \
        --secret-key $SECRET_KEY \
        --session-token $SESSION_TOKEN \
        --query 'Headers["Authorization"]' \
        --output text \
    )" | jq
```

[aws container best practices]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-considerations.html
[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[custom extractor]: https://github.com/tokio-rs/axum/blob/035c8a36b591bb81b8d107c701ac4b14c0230da3/examples/tokio-redis/src/main.rs#L75
[nested extractor]: https://docs.rs/axum/0.7.5/axum/extract/index.html#accessing-other-extractors-in-fromrequest-or-fromrequestparts-implementations
[template dockerfile]: ../rust-builder/template.Dockerfile
[`allowlist` docker hub image]: https://hub.docker.com/repository/docker/econialabs/allowlist/tags
[`axum` graceful shutdown example]: https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs
[`push-allowlist.yaml`]: ../../.github/workflows/push-allowlist.yaml
[`rust-builder`]: ../rust-builder/README.md

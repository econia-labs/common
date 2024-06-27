<!--
cspell:word sadd
cspell:word sismember
cspell:word smembers
-->

# Allowlist

## Start local deployment

```sh
docker compose up --detach
```

## Stop local deployment

```sh
docker compose down
```

## Check if address is allowed

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS | jq
```

## Add address to allowlist

```sh
REQUESTED_ADDRESS=0x123
curl localhost:3000/$REQUESTED_ADDRESS -X POST | jq
```

## References

- [Basic `axum` example]
- [`axum` with Redis example]

[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs

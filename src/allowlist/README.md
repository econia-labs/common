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

## Interactive Redis interaction

With local deployment live, start an interactive session:

```sh
redis-cli
```

Verify the connection:

```sh
ping
```

Add elements to an `allowlist` set:

```sh
SADD allowlist "0x123"
SADD allowlist "0xface"
```

View all members:

```sh
SMEMBERS allowlist
```

Check membership:

```sh
SISMEMBER allowlist "0x123"
```

```sh
SISMEMBER allowlist "0xbee"
```

Exit the session:

```sh
exit
```

## Server commands, local mockup

```sh
curl 0.0.0.0:3000 \
    -d '{ "address": "0x12345" }' \
    -H 'Content-Type: application/json' \
    -X GET
```

```sh
curl 0.0.0.0:3000 \
    -d '{ "address": "0x12345" }' \
    -H 'Content-Type: application/json' \
    -X POST
```

## References

- [Basic `axum` example]
- [`axum` with Redis example]

[basic `axum` example]: https://github.com/tokio-rs/axum/tree/main?tab=readme-ov-file#usage-example
[`axum` with redis example]: https://github.com/tokio-rs/axum/blob/main/examples/tokio-redis/src/main.rs

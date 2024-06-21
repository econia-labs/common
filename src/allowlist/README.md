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

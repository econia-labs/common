<!--- cspell:words wxyz -->

# Contribution Guidelines

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`, `SHOULD`,
`SHOULD NOT`, `RECOMMENDED`,  `MAY`, and `OPTIONAL` in this document are to be
interpreted as described in [RFC 2119].

These keywords `SHALL` be in `monospace` for ease of identification.

## Continuous integration and development

### `pre-commit`

This repository uses [`pre-commit`]. If you add a new filetype, you `SHOULD` add
a new [hook][pre-commit hook] as applicable. The `cfg/` directory has
`pre-commit` configuration files for various hooks. To run:

```sh
source src/sh/pre-commit.sh
```

### GitHub actions

This repository uses [GitHub actions] to perform assorted status checks. If you
submit a pull request but do not [run `pre-commit`] then your pull request might
get blocked.

[run `pre-commit`]: #pre-commit
[github actions]: https://docs.github.com/en/actions
[pre-commit hook]: https://pre-commit.com/hooks.html
[rfc 2119]: https://www.ietf.org/rfc/rfc2119.txt
[`pre-commit`]: https://github.com/pre-commit/pre-commit
# Zeco

This is a work was initiated and supported by [this grant](https://news.perlfoundation.org/post/raku-ecosystem-tonyo)

# Starting the Ecosystem

If you want to play around with this, the code is documented in each file using POD6, and you can start the server via:

```raku
use Zeco;

await start-server;
```

Or, as a one liner:

```
raku -I. -e 'use Zeco; await start-server'
```

Environment variables are automatically set during tests (see Makefile command `make integration`).  For running locally you can set `FEZ_ECO_CONFIG` (see `resources/test-fez-eco-config.toml`) for setting this repo's runtime configuration, and set `FEZ_CONFIG` if you're using the `fez` client as a test client.

# Quickstart for Config

## Str:D db

A postgres uri string to use as a backend for users, dists, groups, and role management.

## Str:D dist-dl-uri

Redirect URL to download a dist.  Eg `dist-dl-uri="https://google.com/"` will forward a request for `ACME.tgz` to `https://google.com/ACME.tgz`.

## Str:D eco-prefix

The prefix the ecosystem should use for verification, eg `zef` in `zef:tony-o`.

## Int:D delete-window

Number of hours a user has to delete a dist they uploaded.

## Int:D port

Port the server should listen on.

## Array[Str] email-command

Shell command to run to send the user an email. The final command will be `[|email-command, to-email, email-type, email-id]`

## Array[Str] dist-move-command

Shell command to run when a dist has been verified and uploaded.  The final command will be `[|dist-move-command, local-path, expected-remote-path]`

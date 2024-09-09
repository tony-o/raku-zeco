# Config

An example config can be found in `resources/test-fez-eco-config.toml`

## `db`

A postgres URI string.

## `eco-prefix`

The prefix for the ecosystem.  This is used as the prefix for the auth str, eg `<this>:username`.

## `delete-window`

Used to determine how long (in hours) a user has to remove an accidentally deleted dist from the ecosystem. Possible values:

1. `> 0`: `delete-window` hours from time uploaded
2. `= 0`: dist can be deleted at any point
3. `< 0`: dists can never be deleted

## `port`

What port to listen on.

## `bucket`

What bucket in AWS S3 to move an uploaded dist to.

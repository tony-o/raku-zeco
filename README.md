# Zeco

This is a work in progress, currently supported under [this grant](https://news.perlfoundation.org/post/raku-ecosystem-tonyo)

More documentation will follow once the code is complete.

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

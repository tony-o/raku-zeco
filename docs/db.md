# DB Tables and Explanations

The ecosystem is intended for use with postgres.

## Schema Changes (Migrations)

Migrations are handled in this repo by making the appropriate files in `resources/migrations/<whatever>.(up|down).sql` and adding that information to the `META6.json` file.  The recommendation for private ecosystems and any PRs following the initial release of this repository is to use the date and time (a POSIX timestamp) as the `<whatever>` to avoid having to refactor your PRs to finally get a clean merge.  All migrations are required to have an up|down file.

## Tables

### `dists`

This table is used primarily for generating the meta listing for package managers.  The `deleted` column with non-null value will filter that column from the final meta listing.  The final meta listing will be a JSON array of the `meta` column.  Any binary indexes intended for package managers are handled by software.

### `keys`

Keys are used as the authentication mechanism for users for performing various actions in the platform.

### `migrations`

The initial creation of this table is handled in `Zeco::DB`. Contains the status of all of the migrations.  More information on how to handle schema changes is listed at the beginning of this document.

### `org_invites`

Org invites is a list of pending org invites containing the intended role.

### `pkeys`

This is a holdover from the zef ecosystem and will go away once that ecosystem is fully migrated.

### `stats`

This table is intended to rollup download activity of packages for consumption in public interfaces, such as raku.land or if you were to build a website on this platform.  This table is updated via a log processor and not real time, and this update is outside of the scope of this repository.  This table is designed for fast querying and does not normalize data (eg use aggregates).  The rollup can be visualized as:

| name | version | dldate | count | _comment_ |
| --- | --- | --- | --- | --- |
| ABC | _NULL_ | 2024-01-01 | 2 | _NULL_ `version` indicates this stat is across all versions, `1` in `dldate` indicates this module was downloaded twice on that date |
| ABC | 1 | 2024-01-01 | 1 | version `1` was downloaded once, accounting for half of the downloads on `2024-01-01` |
| ABC | 2 | 2024-01-01 | 1 | version `2` was downloaded once, accounting for half of the downloads on `2024-01-01` |

### `user_meta`

Public user information, intended for public consumption by web interfaces for ecosystems.

### `users`

This table holds all of the user and group information.  Groups will have a password set to `-`.  Group and user names cannot collide to avoid any issues with name spoofing.  The `email` column here is meant for internal communication and should never be published to the outside world.  Username determines what the expected auth should be, eg `eco:<username>`.

### `group_members`

This is simply a role based mapping between a group and a user.

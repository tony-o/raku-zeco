NAME
====

Zeco::DB

SYNOPSIS
========

Handles DB connections and migrations. To create a schema change for deployment, take the following steps:

    - Create resources/migrations/<posix timestamp>.up.sql
    - Create resources/migrations/<posix timestamp>.down.sql
    - Add the two files to the META6.json manifest.
    - Start the server.


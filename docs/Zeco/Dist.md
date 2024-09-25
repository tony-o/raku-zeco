NAME
====

Zeco::Dist

SYNOPSIS
========

Contains the webserver routes for removing and uploading dists, and for meta listings (in both binary and JSON formats).

POST /remove (Authorization required)
-------------------------------------

    Expects a JSON payload matching a QRemoveDist and a valid Authorization header
    that either owns or has permission to the group of the dist to be removed.

GET /
-----

    Sends either the binary index or a JSON array containing all non-deleted dists
    currently in the ecosystem.  To retrieve the listing as a binary index, supply
    a query string of `?bin=true`.

POST /upload (Authorization required)
-------------------------------------

    Expects a multipart/form-data payload containing the fields outlined in
    QIngestUpload.  Will verify an uploaded dist against the Authorization data
    provided along with performing other basic dist checks. Will ultimately index
    the provided dist in the ecosystem.

GET /upload (Authorization required)
------------------------------------

    DEPRECATED. Do not use and do not develop further. Included here for existing
    ecosystem compatibility.


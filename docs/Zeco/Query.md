NAME
====

Zeco::Query

SYNOPSIS
========

Contains queries used by middleware to load authenticated user data.

method verify-key (Str:D --> Hash)
----------------------------------

    Signature: Str:D $key - the api key for the user making the request.
    Returns: Hash - containing the user data
                    <authkey username expires user_id email>


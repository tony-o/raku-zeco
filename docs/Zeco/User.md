NAME
====

Zeco::User

SYNOPSIS
========

Contains the webserver routes for creating, leaving, and maintaining groups.

GET /init-password-reset
------------------------

    Initializes a password reset for user info contained in query string
    (QInitPasswordReset).

POST /login
-----------

    Attempts to login the user requested in JSON body (QLogin).

POST /password-reset
--------------------

    Completes a password reset for the user given in JSON body (QPasswordReset).
    This endpoint is intended to be used in conjunction with
    /init-password-reset.

POST /register
--------------

    Registers a user with information provided by JSON body (QRegister).

POST /update-meta (Authorization required)
------------------------------------------

    Updates the requesting user's public meta data as requested in JSON body
    (QUpdateUserMeta).


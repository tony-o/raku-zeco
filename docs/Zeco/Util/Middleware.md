NAME
====

Zeco::Util::Middleware

SYNOPSIS
========

This module contains Sparrow middleware for authorization and request parsing, See below for more information about the middleware provided.

method authorize
----------------

    This method looks for an Authorization header. If provided then proceeds to
    verify the api key against the database.  Otherwise it returns an
    Unauthorized response to the user.

method body-parser(QType --> Callable)
--------------------------------------

    Signature - QType - the type to coerce the body into.
    Returns - Callable - middleware for use in Sparrow.


    This method parses the request body of type application/json and transforms
    that data into the type requested by QType. If validation of the request body
    fails after introspecting QType (too many keys, not enough keys, etc) then this
    method returns an error of Teapot containing the actual error information for
    the user to rectify.

method form-parser(QType --> Callable)
--------------------------------------

    Signature - QType - the type to coerce the body into.
    Returns - Callable - middleware for use in Sparrow.


    This method parses the request body of type multipart/form-data and transforms
    that data into the type requested by QType. If validation of the request body
    fails after introspecting QType (too many keys, not enough keys, etc) then this
    method returns an error of Teapot containing the actual error information for
    the user to rectify.

method query-parser(QType --> Callable)
---------------------------------------

    Signature - QType - the type to coerce the query string into.
    Returns - Callable - middleware for use in Sparrow.


    This method parses the request query string of type multipart/form-data and
    transforms that data into the type requested by QType. If validation of the
    request body fails after introspecting QType (too many keys, not enough
    keys, etc) then this method returns an error of Teapot containing the
    actual error information for the user to rectify.


NAME
====

Zeco::Util::BCrypt

SYNOPSIS
========

Contains bindings to libcrypt and provides two methods for hashing and matching a hashed password. `hash-passwd` and `match-passwd`.

method hash-passwd(Str:D --> Str) 
----------------------------------

    Signature: Str - the string to salt and hash.
    Returns: Str - the salted and hashed password. 

    Salts and hashes a password.

method match-passwd(Str:D $password, Str:D $hash-string --> Bool) 
------------------------------------------------------------------

    Signature: $password - the password to match the $hash-string to
               $hash-string - the salted and hashed string generated with
                              hash-passwd
    Returns: Bool - indicates whether the password provided is the same as in the
                    hash-string.

    Checks an inputted password against a securely stored password.


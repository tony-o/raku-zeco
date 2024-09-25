NAME
====

Zeco::Query::Users

SYNOPSIS
========

Methods for handling the processes around user management.

method init-password-reset(QInitPasswordReset:D --> Result) 
------------------------------------------------------------

    Signature: QInitPasswordReset - user information to start a password reset.
    Returns: NotFound - when the auth is not found.
                      - if a unique key failed to generate.
             SuccessFail - when the key was added to the DB but an email failed
                           to send. the user should re-request the password-reset
             Success - email was sent and key was added to the db.

    Emails the user's private email address (not the one used in the meta) with
    a code to be used with the password-reset method.

method login(QLogin:D --> Result) 
----------------------------------

    Signature: QLogin - email and password for the user requesting an api token.
    Returns: NotFound - bad password was supplied.
                      - the auth does not exist.
             UnknownError - when an api-key fails to generate.
             SuccessHashPayload - an api-key is returned. 

    Generates an api key and returns that to the requestor.

method password-reset(QPasswordReset:D --> Result) 
---------------------------------------------------

    Signature: QPasswordReset - object containing the reset key generated from
                                calling init-password-reset
    Returns: NotFound - provided key was incorrect.
                      - auth was not found. 
                      - provided key is expired.
             InvalidPassword - the password update requested is not a valid
                               password.
             Success - the user can proceed to login with the new password.

    Performs a password reset.

method register(QRegister:D --> Result) 
----------------------------------------

    Signature: QRegister - required information to create a new user
    Returns: InvalidPassword - password requested is invalid.
             InvalidEmail - email requested is invalid.
             UsernameExists - the auth already exists.
             EmailExists - the email is already registered.
             Success - the user can proceed to login with the credentials
                       provided.

    Create a new user.

method update-user-meta(QUpdateUserMeta:D, Int:D --> Result) 
-------------------------------------------------------------

    Signature: QUpdateUserMeta - meta data to update for the user 
               Int:D - authenticated user id to update meta for
    Returns: InvalidEmail - the email requested is invalid.
             Success - public information is updated. 

    Allows a user to update their public meta data.

method unsign-upload-key(Str:D --> Result) 
-------------------------------------------

    This method is deprecated and should not be used. Provided here for backwards
    compatibility with existing eco-systems.


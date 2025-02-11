NAME
====

Zeco::Email

SYNOPSIS
========

Contains an shorter interface for sending emails from the server. Will run the command provided in config.email-command

method send-message (QEmail --> Int)
------------------------------------

    Signature: QEmail - contains the email info.
    Returns: Return code from process

    Calling this method will create and call a command as specified from
    config.email-command as:

    <cmd> "<QEmail.to>" "<QEmail.type>" "<QEmail.id>"

    The type to database id mapping is as follows:

    PASSWORD-RESET     password_reset.password_reset_id


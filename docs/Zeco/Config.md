NAME
====

Zeco::Config

SYNOPSIS
========

Loads the config into local class ::Cfg. The search paths for the config loader are:

    - Environment variable FEZ_ECO_CONFIG
    - ${XDG_CONFIG_HOME}/Zeco.toml
    - ${HOME}/.config/Zeco.toml
    - ${APP_DATA}/Zeco.toml
    - ${HOME}/Library/Zeco.toml
    - ./Zeco.toml

If none of those resolve to an existing file then configuration will fail. Valid options are:

    db            = A postgres URI connection string
    port          = Port for the web server to listen on
    eco-prefix    = The first part of the ecosystem's auth, eg "<eco-prefix>:<username>"
    delete-window = A number, in hours, dists are allowed to be deleted.
                    - > 0 means deletion is possible for X hours after uploaded
                    - = 0 means possible any time
                    - < 0 means dists can never be deleted
    email-command = Command to run when a user needs to be emailed
    dist-move-command = Command to run to move a dist to its final destination


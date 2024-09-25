NAME
====

Zeco::Query::Dists

SYNOPSIS
========

Methods for handling the processes around dist management.

method remove-dist(QRemoveDist, $user --> Result)
-------------------------------------------------

    Signature: QRemoveDist - the dist to be removed
               $user       - hash of the pre-authed user
    Returns: a Result object.

    Returns NotFound if the delete window is past or the dist is not found in the
    current index. Returns InvalidAuth if the user does not have permission to
    remove the dist.  Success otherwise.

    This method is intended to remove the dist from the `dists` table when the
    config value `delete-window` (in hours) has not passed, or when the value is
    less than zero. If the config value is zero then a dist can be removed any
    time.

method ingest-upload(QIngestUpload, $user --> Result)
-----------------------------------------------------

    Signature: QIngestUpload - the dist to be indexed 
               $user         - hash of the pre-authed user
    Returns: a Result object

    Does several checks against the dist:

    - Verify the dist can be extracted by standard tooling
      -> UnableToExtractArchive
    - Ensures a META6.json file is present and can be parsed by raku's JSON
      internal methods -> UnableToLocateMeta6
    - Confirms user is a member of the group in the META6's auth or is the
      use in the auth -> InvalidAuth
    - Makes sure the dist name contains at least one a-z0-9 character
      -> InvalidMeta6Json
    - Ensures a `provides` section is there (does not verify contents)
      -> InvalidMeta6Json
    - Runs a script specified by the config to do something with the index
      -> IndexFailed (TODO)
    - Returns Success

    After the checks this will attempt to run the command in
    config.dist-move-command as follows:

    config.dist-move-command <path to .tar.tz> <expected path at destination>

method generate-full-meta(--> Result)
-------------------------------------

    Returns: MetaIndex 

    Retrieves all non-deleted dists from the `dists` table and returns them in a
    nicely typed object (as a list).


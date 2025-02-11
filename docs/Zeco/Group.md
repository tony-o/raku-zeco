NAME
====

Zeco::Group

SYNOPSIS
========

Contains the webserver routes for creating, leaving, and maintaining groups.

GET /group (Authorization required)
-----------------------------------

    Expects a query string containing the information in QCreateGroup. Will create
    the requested group if the namespace is available.

PATCH /groups (Authorization required)
--------------------------------------

    Modifies a group member's role with information provided in query
    QGroupUserRole. See Zec::Query::Group::modify-group for more detailed
    information.

DELETE /group (Authorization required)
--------------------------------------

    Leaves the group provided in the query string (QGroup). If the user is the
    last member then the user must first demote themselves to the `member` role,
    then they will be permitted to abandon the group.

GET /groups (Authorization required)
------------------------------------

    Lists the current user's groups.

POST /groups (Authorization required)
-------------------------------------

    Invites user provided in query string (QGroupUserRole) to the group with the
    requested role.

PUT /groups (Authorization required)
------------------------------------

    Accepts a pending invite described by the query string (QGroup).

GET /groups/invites (Authorization required)
--------------------------------------------

    Returns the current user's pending invites.

POST /groups/members
--------------------

    Returns a list of the group members requested by JSON body (QGroup).

POST /groups/meta (Authorization required)
------------------------------------------

    Updates a group's public meta data as requested by JSON body (QGroupMeta).
    The authorized user must be a group admin to perform this action.


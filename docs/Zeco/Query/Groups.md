NAME
====

Zeco::Query::Groups

SYNOPSIS
========

Methods for handling the processes around group management.

method group-name-to-id(Str:D --> Int)
--------------------------------------

    Signature: Str:D - group name to search for
    Returns: Int - undefined Int if group was not found, otherwise the
             group id to use when performing operations with the group
             name.

    Convenience method, not for use outside of Zeco::Query::*

method group-exists(Str:D --> Bool:D)
-------------------------------------

    Signature: Str:D - group name to search for
    Returns: Bool:D - True if group is found, else False

    Convenience method, not for use outside of Zeco::Query::*

method is-group-admin(Str:D, Int:D --> Bool:D) 
-----------------------------------------------

    Signature: Str:D - group name to check
               Int:D - the user id to check for admin role
    Returns: Bool:D - True if the user id given has the admin role for the group

    Convenience method, not for use outside of Zeco::Query::*

method create-group(QCreateGroup, Int:D --> Result)
---------------------------------------------------

    Signature: QCreateGroup - the group to create
               Int:D - the user id creating the group
    Returns: GroupExists - the auth already exists (as either a user or group).
             InvalidEmail - the email is invalid.
             UnknownError - Something in the DB failed to insert or generate.
             Success - the group can now upload dists and add/remove members.

    Checks:
    - Checks if the group exists -> GroupExists 
    - Email domain has MX records -> InvalidEmail

    Creates an entry in the `users` table with password '-' (indicating a group).
    Adds the user as an admin to the created group.

method modify-group(QGroupUserRole:D, Int:D --> Result)
-------------------------------------------------------

    Signature: QGroupUserRole - the new role information containing:
                                - user email to change roles for
                                - the group name to alter roles in
               Int:D - the user id requesting the change, must be an admin
    Returns: InsufficientRole - requesting user id is not an admin.
             NotFound - the user in QGroupUserRole is not a member of the group
                        or ineligible for role change.
             SuccessFail - the role was changed but an email failed to send.
             Success - the role was changed and the user was emailed an notice. 

    Use this method to alter user roles.

method list-groups(Int:D --> Result) 
-------------------------------------

    Signature: Int:D - authenticated user id to list groups for
    Returns: GroupListing - list of groups the user belongs to

    Returns a string list of the groups the user belongs to.

method leave-group(QGroup:D, Int:D --> Result) 
-----------------------------------------------

    Signature: QGroup - the group information to leave
               Int:D - authenticated user id of the user leaving the group
    Returns: Success - user no longer belongs to the group.
             NotFound - the user is not a member of the group.
                      - the user is the last admin of the group. 

    Removes any roles associated with the current user and group. If the user is
    the last member of the group and they are an admin then this operation will
    fail. To effectively abandon the group a user must first demote themselves to
    a `member` and then leave the group.

method invite-groups(QGroupUserRole:D, Int:D --> Result) 
---------------------------------------------------------

    Signature: QGroupUserRole - the group information containing
                                - invited user's email
                                - group name
                                - the user's role
               Int:D - authenticated user id of the user making the request.
                       this user must be an admin.
    Returns: NotFound - invited user is not registered in the ecosystem.
             ExistingGroupMember - invited user is already a member of the group.
             SuccessFail - invitation was created but email failed to send.
             Success - invitation was created and user was sent an email.

    Makes a group invite for a user to accept or reject.

method accept-invite-groups(QGroup:D, Int:D --> Result) 
--------------------------------------------------------

    Signature: QGroup - group information the user is accepting an invite for
               Int:D  - authenticated user id accepting the invite
    Returns: NotFound - invitation for that user/group combination was not found.
             UnknownError - something happened.
             Success - invitation was converted to a user group role.

    Modifies a group invite to a user role.

method pending-invites-groups(Int:D --> Result) 
------------------------------------------------

    Signature: Int:D  - authenticated user id to retrieve invites for
    Returns: GroupListing - groups and roles the user is invited to become a
                            part of. 

    Lists group invites for the given user.

method members-groups(QGroup:D --> Result) 
-------------------------------------------

    Signature: QGroup - the group to list members of 
    Returns: GroupListing - groups and roles of users in the requested group.

    Lists group members and roles for a given group. All group information
    is intended as public.

method update-meta-groups(QGroupMeta:D, Int:D --> Result)
---------------------------------------------------------

    Signature: QGroupMeta - the valid meta data fields that can be updated
               Int:D - user id making the request.  must be an admin
    Returns: InsufficientRole - requesting user is not an admin of the group.
             NotFound - the group is not registered.
             Success - group info was updated.

    Updates the group's public meta data.


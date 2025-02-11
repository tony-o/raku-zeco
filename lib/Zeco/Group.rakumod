unit module Zeco::Group;

use Humming-Bird::Core;

use Zeco::Query::Groups;
use Zeco::Util::Middleware;
use Zeco::Util::Types;

=begin pod

=NAME
Zeco::Group

=begin SYNOPSIS
Contains the webserver routes for creating, leaving, and maintaining groups.
=end SYNOPSIS

=head2 GET /group (Authorization required)

  Expects a query string containing the information in QCreateGroup. Will create
  the requested group if the namespace is available.

=head2 PATCH /groups (Authorization required)

  Modifies a group member's role with information provided in query
  QGroupUserRole. See Zec::Query::Group::modify-group for more detailed
  information.

=head2 DELETE /group (Authorization required)

  Leaves the group provided in the query string (QGroup). If the user is the
  last member then the user must first demote themselves to the `member` role,
  then they will be permitted to abandon the group.

=head2 GET /groups (Authorization required)

  Lists the current user's groups.

=head2 POST /groups (Authorization required)

  Invites user provided in query string (QGroupUserRole) to the group with the
  requested role.

=head2 PUT /groups (Authorization required)

  Accepts a pending invite described by the query string (QGroup).

=head2 GET /groups/invites (Authorization required)

  Returns the current user's pending invites.

=head2 POST /groups/members

  Returns a list of the group members requested by JSON body (QGroup).

=head2 POST /groups/meta (Authorization required)

  Updates a group's public meta data as requested by JSON body (QGroupMeta).
  The authorized user must be a group admin to perform this action.

=end pod

# create a group
get('/group', -> $req, $res {
  create-group(
    $req.stash<query>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, query-parser(QCreateGroup)]); 

patch('/groups', -> $req, $res {
  modify-group(
    $req.stash<query>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, query-parser(QGroupUserRole)]);

delete('/groups', -> $req, $res {
  leave-group(
    $req.stash<query>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, query-parser(QGroup)]);

get('/groups', -> $req, $res {
  list-groups(
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize]);

post('/groups', -> $req, $res {
  invite-groups(
    $req.stash<query>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, query-parser(QGroupUserRole)]);

put('/groups', -> $req, $res {
  accept-invite-groups(
    $req.stash<query>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, query-parser(QGroup)]);

get('/groups/invites', -> $req, $res {
  pending-invites-groups(
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize]);

post('/groups/members', -> $req, $res {
  members-groups(
    $req.stash<body>,
  ).render($res);
}, [body-parser(QGroup)]);

post('/groups/meta', -> $req, $res {
  update-meta-groups(
    $req.stash<body>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, body-parser(QGroupMeta)]);

unit module Zeco::Group;

use Humming-Bird::Core;

use Zeco::Query::Groups;
use Zeco::Util::Middleware;
use Zeco::Util::Types;

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
}, [&authorize, body-parser(QGroup)]);

post('/groups/meta', -> $req, $res {
  update-meta-groups(
    $req.stash<body>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, body-parser(QGroupMeta)]);

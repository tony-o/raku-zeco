unit module Zeco::User;

use Humming-Bird::Core;

use Zeco::Query::Users;
use Zeco::Util::Middleware;
use Zeco::Util::Types;

=begin pod

=title Zeco::User

=begin SYNOPSIS
Contains the webserver routes for creating, leaving, and maintaining groups.
=end SYNOPSIS

=head2 GET /init-password-reset

  Initializes a password reset for user info contained in query string
  (QInitPasswordReset).

=head2 POST /login

  Attempts to login the user requested in JSON body (QLogin).

=head2 POST /password-reset

  Completes a password reset for the user given in JSON body (QPasswordReset).
  This endpoint is intended to be used in conjunction with
  /init-password-reset.

=head2 POST /register

  Registers a user with information provided by JSON body (QRegister).

=head2 POST /update-meta (Authorization required)

  Updates the requesting user's public meta data as requested in JSON body
  (QUpdateUserMeta).

=head2 GET /meta.json

  Returns a hash of auth to public user meta.

=end pod

get('/init-password-reset', -> $req, $res {
  init-password-reset(
    $req.stash<query>,
  ).render($res);
}, [query-parser(QInitPasswordReset)]);

post('/login', -> $req, $res {
  login(
    $req.stash<body>,
  ).render($res);
}, [body-parser(QLogin)]);

post('/password-reset', -> $req, $res {
  password-reset(
    $req.stash<body>,
  ).render($res);
}, [body-parser(QPasswordReset)]);

post('/register', -> $req, $res {
  register(
    $req.stash<body>,
  ).render($res);
}, [body-parser(QRegister)]);

post('/update-meta', -> $req, $res {
  update-user-meta(
    $req.stash<body>,
    $req.stash<user><user_id>,
  ).render($res);
}, [&authorize, body-parser(QUpdateUserMeta)]);

get('/meta.json', -> $req, $res {
  dump-user-meta.render($res);
});

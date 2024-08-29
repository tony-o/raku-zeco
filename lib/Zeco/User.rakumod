unit module Zeco::User;

use Humming-Bird::Core;

use Zeco::Query::Users;
use Zeco::Util::Middleware;
use Zeco::Util::Types;

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

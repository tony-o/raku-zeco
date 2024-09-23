unit module Zeco::Util::Middleware;

use Zeco::Responses;
use Zeco::Query;
use Zeco::Util::Json;
use Zeco::Util::Types;

sub authorize($req, $res, &n) is export {
  my $hdr  = $req.headers.keys.grep(*.uc eq 'AUTHORIZATION').first // '';
  my $user = verify-key( (S/^'Zef '// given $req.header($hdr)) ) if $hdr ne '';
  if $hdr eq '' || !$user.defined {
    Unauthorized.new.render($res);
    return $res;
  }

  $req.stash<user> = $user;

  n();
}

sub body-parser(QType $type) is export {
  sub ($req, $res, &n) {
    my $bs = $type.from-body($req.body);

    if $bs.^can('error') {
      return $res.status(418).json(to-j({
        :!success,
        :message($bs.error),
      }));
    }

    $req.stash<body> = $bs;

    n();
  };
}

sub form-parser(QType $type) is export {
  sub ($req, $res, &n) {
    my $fs = $type.from-form($req.content);

    if $fs.^can('error') {
      return $res.status(418).json(to-j({
        :!success,
        :message($fs.error),
      }));
    }

    $req.stash<form> = $fs;

    n();
  };
}

sub query-parser(QType $type) is export {
  sub ($req, $res, &n) {
    my $qs = $type.from-qs($req.query);

    if $qs.^can('error') {
      return $res.status(418).json(to-j({
        :!success,
        :message($qs.error),
      }));
    }

    $req.stash<query> = $qs;

    n();
  };
}

unit module Zeco::Util::Middleware;

use Zeco::Responses;
use Zeco::Query;
use Zeco::Util::Json;
use Zeco::Util::Types;

=begin pod

=NAME
Zeco::Util::Middleware

=begin SYNOPSIS
This module contains Sparrow middleware for authorization and request parsing,
See below for more information about the middleware provided.
=end SYNOPSIS

=head2 method authorize

  This method looks for an Authorization header. If provided then proceeds to
  verify the api key against the database.  Otherwise it returns an
  Unauthorized response to the user.

=head2 method body-parser(QType --> Callable)

  Signature - QType - the type to coerce the body into.
  Returns - Callable - middleware for use in Sparrow.
  

  This method parses the request body of type application/json and transforms
  that data into the type requested by QType. If validation of the request body
  fails after introspecting QType (too many keys, not enough keys, etc) then this
  method returns an error of Teapot containing the actual error information for
  the user to rectify.

=head2 method form-parser(QType --> Callable)

  Signature - QType - the type to coerce the body into.
  Returns - Callable - middleware for use in Sparrow.
  

  This method parses the request body of type multipart/form-data and transforms
  that data into the type requested by QType. If validation of the request body
  fails after introspecting QType (too many keys, not enough keys, etc) then this
  method returns an error of Teapot containing the actual error information for
  the user to rectify.

=head2 method query-parser(QType --> Callable)

  Signature - QType - the type to coerce the query string into.
  Returns - Callable - middleware for use in Sparrow.
  

  This method parses the request query string of type multipart/form-data and
  transforms that data into the type requested by QType. If validation of the
  request body fails after introspecting QType (too many keys, not enough
  keys, etc) then this method returns an error of Teapot containing the
  actual error information for the user to rectify.

=end pod

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

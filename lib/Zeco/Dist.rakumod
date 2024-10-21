unit module Zeco::Dist;

use Humming-Bird::Core;

use Zeco::Responses;
use Zeco::Util::Middleware;
use Zeco::Util::Types;
use Zeco::Query::Dists;

=begin pod

=NAME
Zeco::Dist

=begin SYNOPSIS
Contains the webserver routes for removing and uploading dists, and for meta
listings (in both binary and JSON formats).
=end SYNOPSIS

=head2 POST /remove (Authorization required)

  Expects a JSON payload matching a QRemoveDist and a valid Authorization header
  that either owns or has permission to the group of the dist to be removed.

=head2 GET /

  Sends either the binary index or a JSON array containing all non-deleted dists
  currently in the ecosystem.  To retrieve the listing as a binary index, supply
  a query string of `?bin=true`.

=head2 POST /upload (Authorization required)

  Expects a multipart/form-data payload containing the fields outlined in
  QIngestUpload.  Will verify an uploaded dist against the Authorization data
  provided along with performing other basic dist checks. Will ultimately index
  the provided dist in the ecosystem.

=head2 GET /upload (Authorization required)

  DEPRECATED. Do not use and do not develop further. Included here for existing
  ecosystem compatibility.

=end pod

post('/remove', -> $req, $res {
  remove-dist(
    $req.stash<body>,
    $req.stash<user>,
  ).render($res);
}, [&authorize, body-parser(QRemoveDist)]);

get('/index.json', -> $req, $res {
  $res.redirect("/{$req.query<bin> ~~ 't'|'true'|'1'|'one' ?? '?bin=t' !! ''}", :permanent);
});

get('/', -> $req, $res {
  generate-full-meta().render($res, :bin($req.query<bin> ~~ 't'|'true'|'1'|'one'));
});

post('/upload', -> $req, $res {
  #upload
  ingest-upload(
    $req.stash<form>,
    $req.stash<user>,
  ).render($res);
}, [&authorize, form-parser(QIngestUpload)]);

get('/upload', -> $req, $res {
  Result
    .new(:!success,
         :status(421),
         :message('This endpoint is deprecated, please update your tooling'))
    .render($res);
}, [&authorize]);

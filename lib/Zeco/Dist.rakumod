unit module Zeco::Dist;

use Humming-Bird::Core;

use Zeco::Exceptions;
use Zeco::Util::Middleware;
use Zeco::Util::Types;
use Zeco::Query::Dists;

post('/remove', -> $req, $res {
  remove-dist(
    $req.stash<body>,
    $req.stash<user>,
  ).render($res);
}, [&authorize, body-parser(QRemoveDist)]);

get('/', -> $req, $res {
  generate-full-meta().render($res);
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

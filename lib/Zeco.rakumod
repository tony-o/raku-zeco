unit module Zeco;

use Humming-Bird::Core;
use Humming-Bird::Advice;


use Zeco::Config;
use Zeco::Group;
use Zeco::User;
use Zeco::Dist;
use Zeco::Util::Json;

advice(-> $res {
  try {
    CATCH {
      default {
        $res.body = $res.body.WHAT ~~ Buf
                 ?? $res.body
                 !! to-json({
                      :!success,
                      :error($res.body),
                    });
      }
    }
    from-json($res.body);
  };
  $res;
});
advice(&advice-logger);
error(X::AdHoc, -> $exn, $res {
  $res.status(500).json(to-json({
    :!success,
    :exception($exn),
  }));
});

listen(config.port);

unit module Zeco;

use Humming-Bird::Core;
use Humming-Bird::Advice;

use Zeco::Config;
use Zeco::Group;
use Zeco::User;
use Zeco::Dist;
use Zeco::Util::Json;

=NAME
Zeco

=begin SYNOPSIS
  raku -MZeco

  Starts the default server.
=end SYNOPSIS

advice(-> $res {
  try {
    CATCH {
      default {
        $res.body = $res.body.WHAT ~~ Buf
                 ?? $res.body
                 !! to-j({
                      :!success,
                      :error($res.body),
                    });
      }
    }
    from-j($res.body);
  };
  $res;
});
advice(&advice-logger);
error(X::AdHoc, -> $exn, $res {
  $res.status(500).json(to-j({
    :!success,
    :exception($exn),
  }));
});


sub start-server is export { listen(config.port); }

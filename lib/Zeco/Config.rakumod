unit module Zeco::Config;

use TOML;

class Cfg {
  has Str $.db;
  has Int $.port;
  has Str $.bucket;
  has Str $.email-key;

  submethod BUILD(Str:D :$!db,
                  Str:D :$!bucket,
                  Int:D :$!port = 8080,
                  Str:D :$!email-key = 'unset',
                 )
    { }
}

sub config(--> Cfg) is export {
  my $cfg-path = (%*ENV<FEZ_ECO_CONFIG> ~~ Str ?? %*ENV<FEZ_ECO_CONFIG>.IO !! Nil)
    // (%*ENV<XDG_CONFIG_HOME>
      // (%*ENV<HOME>.IO.add('.config').e ?? %*ENV<HOME>.IO.add('.config') !! Nil)
      // %*ENV<APP_DATA>
      // (%*ENV<HOME>.IO.add('Library').e ?? %*ENV<HOME>.IO.add('Library') !! Nil)
      // '.'
    ).IO.add('Zeco.toml');

  die "Unable to determine default configuration path, expecting: {$cfg-path}"
    unless $cfg-path.e;
    
  my $cfg = from-toml($cfg-path.slurp);
  my %exp = Cfg.^attributes
               .map({ 
                 $cfg{$_.name.substr(2)}.defined
                 ?? ($_.name.substr(2) => $cfg{$_.name.substr(2)})
                 !! Empty 
               });
  my @extras = $cfg.keys.grep({!(%exp{$_}:exists)}).sort;

  $*ERR.say: "Extra keys in config, ignoring: {@extras.join(", ")}"
    if +@extras;

  Cfg.new(|%exp);
}

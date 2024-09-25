unit module Zeco::Config;

use TOML;

=begin pod

=NAME
Zeco::Config

=begin SYNOPSIS
Loads the config into local class ::Cfg. The search paths for the config loader are:
 
  - Environment variable FEZ_ECO_CONFIG
  - ${XDG_CONFIG_HOME}/Zeco.toml
  - ${HOME}/.config/Zeco.toml
  - ${APP_DATA}/Zeco.toml
  - ${HOME}/Library/Zeco.toml
  - ./Zeco.toml

If none of those resolve to an existing file then configuration will fail.  Valid options are:

  db            = A postgres URI connection string
  port          = Port for the web server to listen on
  eco-prefix    = The first part of the ecosystem's auth, eg "<eco-prefix>:<username>"
  delete-window = A number, in hours, dists are allowed to be deleted.
                  - > 0 means deletion is possible for X hours after uploaded
                  - = 0 means possible any time
                  - < 0 means dists can never be deleted
  email-command = Command to run when a user needs to be emailed
  dist-move-command = Command to run to move a dist to its final destination
=end SYNOPSIS

=end pod

class Cfg {
  has Str $.db;
  has Int $.port;
  has Int $.delete-window;
  has Str $.eco-prefix;
  has @.email-command;
  has @.dist-move-command;

  submethod BUILD(Str:D :$!db,
                  Int:D :$!delete-window,
                  Str:D :$!eco-prefix,
                  Int:D :$!port = 8080,
                  :@!email-command,
                  :@!dist-move-command,
                 )
    { }
}

sub get-config(--> Cfg) {
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

sub config(--> Cfg) is export { once get-config }

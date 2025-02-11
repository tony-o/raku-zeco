unit module Zeco::DB;

use DB::Pg;
use Zeco::Config;

=begin pod

=NAME
Zeco::DB

=begin SYNOPSIS
Handles DB connections and migrations. To create a schema change for deployment, take the following steps:

  - Create resources/migrations/<posix timestamp>.up.sql
  - Create resources/migrations/<posix timestamp>.down.sql
  - Add the two files to the META6.json manifest.
  - Start the server.
=end SYNOPSIS

=end pod

sub migrate() {
  my $db = DB::Pg.new(conninfo => config.db);
  return $db if %*ENV<SKIP_MIGRATIONS>;

  my %migrations;
  for |$?DISTRIBUTION.meta<resources> -> $r {
    next if ($r.Str.index('migrations/') // -1) != 0;
    my @parts = $r.IO.basename.split('.');
    my $name = @parts[0..*-3].join('.');
    my $dir  = @parts[*-2];
    %migrations{$name} //= {};
    %migrations{$name}{$dir} = %?RESOURCES{$r};
  }

  $db.query(q:to/EOS/);
  DO $$ BEGIN
    CREATE TYPE migration_status AS ENUM ('complete', 'error', 'skipped');
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END $$;
  EOS

  $db.query(q:to/EOS/);
  CREATE TABLE IF NOT EXISTS migrations (
    id     serial NOT NULL PRIMARY KEY,
    file   text   NOT NULL,
    status migration_status NOT NULL
  );
  EOS

  my %existing-migrations = $db.query('SELECT * FROM migrations;').hashes.map({ $_<file> => $_<status> // Nil });

  for %migrations.keys.sort -> $mig {
    next if %existing-migrations{$mig};
    try {
      CATCH {
        default {
          $db.query('INSERT INTO migrations (file, status) VALUES ($1, \'error\');', $mig); 
          $*ERR.say: $_;
          exit 1;
        }
      }
      $db.execute(%migrations{$mig}<up>.IO.slurp);
      $db.query('INSERT INTO migrations (file, status) VALUES ($1, \'complete\');', $mig); 
    };
  }

  
  if %*ENV<MIGRATIONS_ONLY> {
    say 'All migrations run, exiting due to MIGRATIONS_ONLY being set';
    exit 0;
  }

  $db;
}

my $pool = once migrate;

sub db() is export { $pool }

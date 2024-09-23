unit module TestIntegration;

use Zeco::DB;
use Zeco::Config;

my %tbls = db.query('SELECT tablename FROM pg_tables WHERE schemaname = \'public\';')
  .hashes
  .map({ $_<tablename> => True });
die "Not a test db, expect table 'test_db' but did not find it. (conninfo={config.db})" unless %tbls<test_db>; 

my @failed;
my $fail-cnt = 1;
while $fail-cnt > 0 {
  my $last-count = $fail-cnt;
  $fail-cnt = 0;
  for %tbls.keys -> $tbl {
    next if $tbl eq 'migrations';
    try {
      CATCH { default { dd $_; $fail-cnt++; } };
      db.query("TRUNCATE $tbl CASCADE;");
    };
  }
  die "Could not truncate all test tables" if $fail-cnt == $last-count;
}
say 'truncated...';

my $server = Proc::Async.new('raku', '-I.', '-e', 'use Zeco; await start-server');
my Promise $started .=new;
$server.stdout.tap(-> $v { 
  $*ERR.say: $v;
  $started.keep if $v.index('listening on port');
});
$server.stderr.tap(-> $v { 
  $*ERR.say: $v;
});
my $starter = $server.start;

await $started;

END {
  try $server.kill;
  await $starter;
}

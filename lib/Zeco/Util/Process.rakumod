unit module Zeco::Util::Process;

sub proc(*@_) is export {
  my $run = Proc::Async.new(|@_);
  my $out = '';
  my $err = '';
  $run.stdout.tap(-> $v { $out ~= $v; });
  $run.stderr.tap(-> $v { $err ~= $v; });

  my $promise = await $run.start;

  $promise.exitcode, $out, $err;  
}

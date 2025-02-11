unit module Zeco::Util::Process;

=begin pod

=NAME
Zeco::Util::Process

=begin SYNOPSIS
This is a convenience wrapper around Proc::Async.
=end SYNOPSIS

=head2 method proc(*@ --> List[$exit-code, $stdout, $stderr])
  
  Signature: *@ - all of the arguments to pass to Proc::Async.new.
  Returns: List[$exit-code, $stdout, $stderr]

  Convenience method to run Proc::Async and capture the program's output, any
  errors, and the exit-code of the process.

=end pod

sub proc(*@_) is export {
  my $run = Proc::Async.new(|@_);
  my $out = '';
  my $err = '';
  $run.stdout.tap(-> $v { $out ~= $v; });
  $run.stderr.tap(-> $v { $err ~= $v; });

  my $promise = await $run.start;

  $promise.exitcode, $out, $err;  
}

use Test;
use Zeco::Util::Json;
unit class TestRender;

has $!status = -1;
has $!body   = '';

submethod BUILD (:$!status, :$!body) { };

method status(Int:D $!status) { self; };
method json(Str:D $body) { $!body = $body eq '' ?? {} !! from-j($body); self; };

method body { $!body };

method assert(Int:D $status, $body, Bool:D :$ignore-body = False, Str :$tag = '') {
  my $pfx = $tag eq '' ?? '' !! ' - ';
  ok $!status == $status, "{$tag}{$pfx}response status matches(expect:$status, got:$!status)";
  return if $ignore-body;
  my $b1 = $body ~~ Str && $body ne '' ?? from-j($body) !! $body // {};
  is-deeply $!body, $b1, "{$tag}{$pfx}body is as expected";
}

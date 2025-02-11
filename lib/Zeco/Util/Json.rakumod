unit package Zeco::Util::Json;

=begin pod

=NAME
Zeco::Util::Json

=begin SYNOPSIS
Uses the Rakudo internals for json parsing. The reasoning behind this is to
ensure that rakudo is able to install/parse the meta data provided in uploaded
dists and that the binary indexes created by this software are readable by
rakudo.  This module exports `to-j` and `from-j` and they can be used inter-
changably with `to-json` and `from-json`.
=end SYNOPSIS

=end pod

sub to-j($t)   is export { ::("Rakudo::Internals::JSON").to-json($t, :pretty, :sorted-keys);   }
sub from-j($t) is export { ::("Rakudo::Internals::JSON").from-json($t); }

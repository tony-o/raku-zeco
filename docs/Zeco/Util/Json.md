NAME
====

Zeco::Util::Json

SYNOPSIS
========

Uses the Rakudo internals for json parsing. The reasoning behind this is to ensure that rakudo is able to install/parse the meta data provided in uploaded dists and that the binary indexes created by this software are readable by rakudo. This module exports `to-j` and `from-j` and they can be used inter- changably with `to-json` and `from-json`.


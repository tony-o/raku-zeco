unit module Zeco::Util::Test;

sub get-fez-config-location(--> Str) is export { %?RESOURCES<test-fez-config.json>.IO.absolute };
sub get-Zeco-config(--> Str) is export { %?RESOURCES<test-Zeco-config.toml>.IO.absolute };

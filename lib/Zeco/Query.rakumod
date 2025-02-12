unit module Zeco::Query;

use Zeco::DB;

=begin pod

=title Zeco::Query

=begin SYNOPSIS
Contains queries used by middleware to load authenticated user data.
=end SYNOPSIS

=head2 method verify-key (Str:D --> Hash)

  Signature: Str:D $key - the api key for the user making the request.
  Returns: Hash - containing the user data
                  <authkey username expires user_id email>

=end pod 

sub verify-key(Str:D $key --> Hash) is export {
  constant $sql = q:to/EOS/;
    SELECT authkey, username, expires, u.user_id, email
    FROM users u
    LEFT JOIN keys p ON p.user_id = u.user_id
    WHERE p.authkey = $1
      AND p.expires > $2
  EOS
  
  my $result = db.query($sql, $key, DateTime.now.posix).hash;
  return Hash unless $result;
  $result;
}

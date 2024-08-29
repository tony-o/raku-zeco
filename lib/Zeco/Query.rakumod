unit module Zeco::Query;

use Zeco::DB;

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

sub get-uid(Str:D $username --> Int) is export {
  constant $sql = q:to/EOS/;
    SELECT user_id
    FROM users
    WHERE username = $1;
  EOS
  
  db.query($sql, $username).hash<user_id> // Int
}

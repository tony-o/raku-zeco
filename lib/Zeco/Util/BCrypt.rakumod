unit module Zeco::Util::BCrypt;

use NativeCall;
use Crypt::Random;

=begin pod

=NAME
Zeco::Util::BCrypt

=begin SYNOPSIS
Contains bindings to libcrypt and provides two methods for hashing and matching
a hashed password.  `hash-passwd` and `match-passwd`.
=end SYNOPSIS


=head2 method hash-passwd(Str:D --> Str) 

  Signature: Str - the string to salt and hash.
  Returns: Str - the salted and hashed password. 

  Salts and hashes a password.

=head2 method match-passwd(Str:D $password, Str:D $hash-string --> Bool) 

  Signature: $password - the password to match the $hash-string to
             $hash-string - the salted and hashed string generated with
                            hash-passwd
  Returns: Bool - indicates whether the password provided is the same as in the
                  hash-string.

  Checks an inputted password against a securely stored password.

=end pod

sub crypt(Str $key is encoded('utf8'), Str $setting is encoded('utf8'))
  is native('crypt')
  returns Str
  { * };

sub crypt_gensalt(Str $prefix is encoded('utf8'), uint32 $count, Buf $input, size_t $size)
  is native('crypt')
  returns Str
  { * };

sub hash-passwd(Str $password --> Str) is export {
  crypt($password, crypt_gensalt('$2b$', 12, crypt_random_buf(16), 128));
}

sub match-passwd(Str $password, Str $hash --> Bool) is export {
  crypt($password, $hash) eq $hash;
}

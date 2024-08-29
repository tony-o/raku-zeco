unit module Zeco::Util::BCrypt;

use NativeCall;
use Crypt::Random;

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

unit module Zeco::Query::Users;

use Digest::SHA1::Native;
use Email::Valid;

use Zeco::DB;
use Zeco::Email;
use Zeco::Exceptions;
use Zeco::Util::BCrypt;
use Zeco::Util::Types;

sub init-password-reset(QInitPasswordReset:D $ipr --> Result) is export {
  constant $sql = q:to/EOS/;
    INSERT INTO password_reset (user_id, key, expires)
                        VALUES ($1,      $2,  $3)
    RETURNING key;
  EOS
  constant $usr = q:to/EOS/;
    SELECT user_id, email
    FROM users
    WHERE username = $1
      AND password <> '-';
  EOS

  my $d = db.db;
  try {
    CATCH { $d.rollback; }
    $d.begin;
    my $user = db.query($usr, $ipr.auth).hash;

    return NotFound.new unless $user && $user<user_id>;

    my $key = (|("A".."Z"),|("a".."z"),|("0".."9")).roll(64).join();

    my $res = db.query($sql, $user<user_id>, $key, DateTime.now.posix+300).hash;
    return NotFound.new if ($res<key>//'') ne $key;
   
    try { 
      my $mesult;
      CATCH {
        return SuccessFail.new if $mesult<message> ne 'Queued. Thank you.';
      };
      $mesult = send-message(message(
        :to($user<email>),
        :subject('Password Reset - Zef Ecosystem'),
        :text("Please re-initiate the password reset"),
      ));
    };
  };
  $d.finish;

  Success.new;
}

sub login(QLogin:D $l --> Result) is export {
  constant $sql = q:to/EOS/;
    SELECT user_id, password FROM users WHERE username = $1;
  EOS

  constant $key-sql = q:to/EOS/;
    INSERT INTO keys (user_id, authkey, expires)
              VALUES ($1,      $2,      $3)
    RETURNING key_id;
  EOS

  my $res = db.query($sql, $l.username).hash;

  return NotFound.new unless $res && $res<password>;

  return NotFound.new(:message('Password invalid or user does not exist'))
    unless match-passwd($l.password, $res<password>.Str);

  my ($key, $ins, $tries);
  $tries = 15;
  while $tries-- > 0 {
    $key = sha1-hex(DateTime.now.posix.Int.Str ~ $l.username ~ rand);
    $ins = try { db.query($key-sql, $res<user_id>, $key, DateTime.now.posix+2_592_000).hash; };
    last if $ins<key_id>;
  }
  return UnknownError.new unless $ins && $ins<key_id>;

  SuccessHashPayload.new(:json({ :$key }));
}

sub password-reset(QPasswordReset:D $reset --> Result) is export {
  constant $sql-s = q:to/EOS/;
    SELECT a.user_id, a.expires, b.username
    FROM password_reset a
    LEFT JOIN users b on a.user_id = b.user_id
    WHERE b.username = $1
      AND a.key = $2
      AND b.password <> '-';
  EOS

  constant $sql-u = q:to/EOS/;
    UPDATE users SET password = $1 WHERE user_id = $2
    RETURNING user_id;
  EOS

  constant $sql-d = q:to/EOS/;
    DELETE FROM password_reset WHERE key = $1 OR expires < $2;
  EOS
  
  my $d = db.db;
  my $r = False;
  try {
    CATCH { $d.rollback; }
    $d.begin;
    my $res = db.query($sql-s, $reset.auth, $reset.key).hash;

    return NotFound.new unless $res && $res<user_id> && $res<expires>;

    return NotFound.new(:message('Reset key has expired, please reinitiate the password reset and try again'))
      unless DateTime.now.posix <= $res<expires>;

    return InvalidPassword.new
      unless $reset.password.chars >= InvalidPassword.MIN_LEN;

    my $upd = db.query($sql-u, hash-passwd($reset.password), $res<user_id>).hash;
    die 'Uh oh!' if $upd<user_id> != $res<user_id>;

    db.query($sql-d, $reset.key, DateTime.now.posix);
    $r = True;
  }

  $d.finish;

  Success.new;
}

constant EMAIL-VALIDATOR = Email::Valid.new(:simple, :mx_check);
sub register(QRegister:D $reg --> Result) is export {
  constant $sql1 = q:to/EOS/;
    SELECT username, email FROM users WHERE username = $1 OR email = $2 LIMIT 1;
  EOS
  constant $sql-i = q:to/EOS/;
    INSERT INTO users (email, username, password)
               VALUES ($1,    $2,       $3)
    RETURNING user_id;
  EOS

  return InvalidPassword.new
    unless $reg.password.chars >= InvalidPassword.MIN_LEN;
  return InvalidEmail.new
    unless EMAIL-VALIDATOR.validate($reg.email); 

  my $res = db.query($sql1, $reg.username, $reg.email).hash;
  return UsernameExists.new
    if $res.keys && $res<username> eq $reg.username;
  return EmailExists.new
    if $res.keys && $res<email> eq $reg.email;

  $res = db.query($sql-i, $reg.email, $reg.username, hash-passwd($reg.password)).hash;

  dd $res;
  die 'Uh oh!' unless $res<user_id>;

  Success.new;
}

sub update-user-meta(QUpdateUserMeta:D $meta, Int:D $user-id --> Result) is export {
  constant $sql-s = q:to/EOS/;
    SELECT user_meta_id, key
    FROM user_meta
    WHERE user_id = $1;
  EOS
  
  constant $sql-u = q:to/EOS/;
    UPDATE user_meta SET value = $1
    WHERE user_meta_id = $2;
  EOS

  constant $sql-i = q:to/EOS/;
    INSERT INTO user_meta (user_id, key, value)
                   VALUES ($1,      $2,  $3);
  EOS

  if $meta.email.defined && $meta.email ne '' {
    return InvalidEmail.new
      unless try EMAIL-VALIDATOR.validate($meta.email);
  }

  my %ms = db.query($sql-s, $user-id).hashes.map({ $_<key> => $_<user_meta_id> });
  my ($name, $val, $res);
  for $meta.^attributes -> $attr {
    $name = $attr.name.substr(2);
    $val  = $attr.get_value($meta);
    next unless $val.defined;
    if %ms{$name}.defined {
      db.query($sql-u, $val, %ms{$name});
    } else {
      db.query($sql-i, $user-id, $name, $val);
    }
  }

  Success.new;
}

sub unsign-upload-key(Str:D $key --> Result) is export {
  constant $sql-s = q:to/EOS/;
    SELECT username FROM users u LEFT JOIN pkeys p ON p.user_id = u.user_id
    WHERE p.prekey = $1;
  EOS
  constant $sql-d = q:to/EOS/;
    DELETE FROM pkeys WHERE prekey = $1;
  EOS
  my $m = db.query($sql-s, $key).hash;
  return NotFound.new unless $m<username>;

  db.query($sql-d, $key);

  return Success.new(message => $m<username>);
}

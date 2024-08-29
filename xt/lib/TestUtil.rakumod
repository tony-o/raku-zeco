unit module TestUtil;
use Zeco::DB;

sub email is export { 'tonyo@test.com' };
sub email2 is export { 'test@test.com' };
sub grup is export { 'abc@xyz.com' };
sub cleanup is export {
  my @emails = email, email2, grup;

  for [email, email2, grup] -> $e {
    die 'db does not contain localhost' unless db.conninfo.index('localhost');
    db.query('delete from password_reset where user_id in (select user_id from users where email = $1);', $e);
    db.query('delete from keys where user_id in (select user_id from users where email = $1)', $e);
    db.query('delete from user_meta where user_id in (select user_id from users where email = $1)', $e);
    db.query('delete from group_members where member_id in (select user_id from users where email = $1)', $e);
    db.query('delete from org_invites where member_id in (select user_id from users where email = $1)', $e);
    db.query('delete from users where email = $1', $e);
  }
};

sub meta($usr = email) is export {
  my %ms;
  for db.query('select key, value from user_meta where user_id in (select user_id from users where email = $1);', $usr).arrays -> $a {
    %ms{$a[0]} = $a[1];
  }
  %ms;
}

sub user-id($usr = email) is export { db.query('select user_id from users where email = $1', $usr).hash<user_id>; }

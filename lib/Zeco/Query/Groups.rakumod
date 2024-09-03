unit module Zeco::Query::Groups;

use Mailgun;
use Net::DNS;

use Zeco::DB;
use Zeco::Email;
use Zeco::Responses;
use Zeco::Query;
use Zeco::Util::Types;

sub group-name-to-id(Str:D $group-name --> Int) is export {
  constant $sql = q:to/EOS/;
    SELECT user_id
    FROM users
    WHERE username = $1
      AND password = '-';
  EOS
  
  db.query($sql, $group-name).hash<user_id> // Int;
}

sub group-exists(Str:D $name --> Bool) is export {
  constant $sql = q:to/EOS/;
    SELECT count(*) as c FROM users WHERE username = $1;
  EOS
  db.query($sql, $name).hash<c> > 0;
}

sub create-group(QCreateGroup:D $qg, Int:D $user-id --> Result) is export {
  constant $sql-g = q:to/EOS/;
    INSERT INTO users (email, username, password)
               VALUES ($1,    $2,       '-')
    RETURNING user_id;
  EOS
  constant $sql-gm = q:to/EOS/;
    INSERT INTO group_members (group_id, member_id, role)
                       VALUES ($1,       $2,        $3)
                    RETURNING role;
  EOS

  return GroupExists.new if group-exists($qg.group);
  return InvalidEmail.new
    unless Net::DNS.new('8.8.8.8').lookup-mx(($qg.email.split('@', 2)[*-1])).elems;

  my $result;
  my $d = db.db;
  try {
    CATCH { $d.rollback; };
    $d.begin;

    my $s1 = $d.prepare($sql-g);
    my $s2 = $d.prepare($sql-gm);

    $result = $s1.execute($qg.email, $qg.group).hash;
    return UnknownError.new unless $result && $result<user_id>;

    $result = $s2.execute($result<user_id>, $user-id, 'admin').hash;

    $result && $result<role> eq 'admin' && $d.commit;
  };

  $d.finish;

  $result && $result<role> eq 'admin'
  ?? Success.new
  !! UnknownError.new;
}

sub is-group-admin(Str:D $group, Int:D $user-id --> Bool) is export {
  constant $sql = q:to/EOS/;
    SELECT count(*) c
    FROM group_members gm
    LEFT JOIN users u
           ON u.user_id = gm.member_id
    WHERE u.user_id     = $1
      AND gm.group_id = (
        SELECT user_id
        FROM users
        WHERE username = $2
          AND password = '-'
        LIMIT 1
        )
      AND gm.role::text = 'admin';
  EOS
  (db.query($sql, $user-id, $group).hash<c>//0) > 0
}

sub modify-group(QGroupUserRole:D $qg, Int:D $user-id --> Result) is export {
  return InsufficientRole.new unless is-group-admin($qg.group, $user-id);

  constant $sql-ensure-role-exists = q:to/EOS/;
    SELECT user_id, email, COALESCE(gm.role::text, '') as role, gm.group_id
    FROM users u
    LEFT JOIN group_members gm
           ON gm.member_id = u.user_id
          AND gm.group_id = (
                SELECT user_id
                FROM users
                WHERE username = $2
                  AND password = '-'
                LIMIT 1
              )
    WHERE username =  $1
      AND password <> '-';
  EOS

  constant $sql-update-role = q:to/EOS/;
    UPDATE group_members
       SET role = $1
     WHERE group_id  = $2
       AND member_id = $3
    RETURNING member_id;
  EOS

  my $result = db.query($sql-ensure-role-exists, $qg.user, $qg.group).hash;
  return NotFound.new unless $result && $result<role> ne '';

  my $uresult = db.query($sql-update-role, $qg.role, $result<group_id>, $result<user_id>).hash;

  return UnknownError.new unless ($uresult<member_id>//0) == $result<user_id>;

  my $mesult = send-message(message(
    :to($result<email>),
    :subject("Org Role Update: '{$qg.group}' - Zef Ecosystem"),
    :text("You're role in '{$qg.group}' has been changed to: {$qg.role}"),
  ));
  return SuccessFail.new if $mesult<message> ne 'Queued. Thank you.';

  Success.new
}

sub leave-group(QGroup:D $qg, Int:D $user-id --> Result) is export {
  constant $sql = q:to/EOS/;
    DELETE FROM group_members
    WHERE group_id  = $1
      AND member_id = $2
      AND (  role = 'member'
          OR 1 < (
            SELECT COUNT(*)
            FROM group_members
            WHERE group_id = $1
              AND role = 'admin'
          ))
    RETURNING member_id;
  EOS

  my $group-id = group-name-to-id($qg.group);
  (db.query($sql, $group-id, $user-id).hash<member_id>//0) == $user-id
  ?? Success.new
  !! NotFound.new(:message('Not found. If you\'re the last member then you need to demote yourself to member and then leave.  This is to avoid accidentally orphaned orgs.'));
}

sub list-groups(Int:D $user-id --> Result) is export {
  constant $sql = q:to/EOS/;
    SELECT u.username as name, role
    FROM group_members gm
    LEFT JOIN users u
           ON u.user_id = group_id
    WHERE gm.member_id = $1;
  EOS
  my $res = db.query($sql, $user-id).hashes;
  GroupListing.new(payload=>$res); 
}

sub invite-groups(QGroupUserRole:D $qg, Int:D $user-id --> Result) is export {
  return InsufficientRole.new unless is-group-admin($qg.group, $user-id);

  constant $sql-check = q:to/EOS/;
    SELECT user_id, email, COALESCE(gm.role::text, '') r
    FROM users u
    LEFT JOIN group_members gm
           ON gm.member_id = u.user_id
          AND gm.group_id = $1
    WHERE username = $2 AND password <> '-';
  EOS
  constant $sql = q:to/EOS/;
    INSERT INTO org_invites (group_id, member_id, role, expires)
    VALUES ((SELECT user_id 
             FROM users
             WHERE username = $1
               AND password = '-'
             LIMIT 1),
            $2,
            $3,
            $4)
    RETURNING member_id;
  EOS

  my $guid = group-name-to-id($qg.group); 
  my $u = db.query($sql-check, $guid, $qg.user).hash;
  return NotFound.new unless $u;
  return ExistingGroupMember.new if $u<r> ne '';

  my $ins = db.query($sql, $qg.group, $u<user_id>, $qg.role, DateTime.now.posix+259200).hash;
  return NotFound.new unless $ins;

  my $mesult = send-message(message(
    :to($u<email>),
    :subject("Org Invite: {$qg.group} - Zef Ecosystem"),
    :text("You were invited to '{$qg.group}'. Please use `fez org accept '{$qg.group}'` to join, otherwise you can ignore this message."),
  ));
  return SuccessFail.new if $mesult<message> ne 'Queued. Thank you.';
  
  Success.new;
}

sub accept-invite-groups(QGroup:D $qg, Int:D $user-id --> Result) is export {
  constant $sql-s = q:to/EOS/;
    SELECT group_id, member_id, role
    FROM org_invites
    WHERE member_id = $1
      AND group_id = (
            SELECT user_id
            FROM users
            WHERE username = $2
              AND password = '-'
            LIMIT 1
          )
     AND expires >= $3;
  EOS

  constant $sql-g = q:to/EOS/;
    SELECT count(*) cnt
    FROM group_members
    WHERE group_id = $1
      AND member_id = $2;
  EOS

  constant $sql-i = q:to/EOS/;
    INSERT INTO group_members (group_id, member_id, role)
                       VALUES ($1,       $2,        $3)
    RETURNING member_id;
  EOS

  constant $sql-d = q:to/EOS/;
    DELETE FROM org_invites
    WHERE (    group_id  = $1
           AND member_id = $2
          )
       OR expires < $3
   RETURNING member_id;
  EOS


  my @res = db.query($sql-s, $user-id, $qg.group, DateTime.now.posix).hashes;
  return NotFound.new unless +@res;
  
  my $already-exists = db.query($sql-g, @res[0]<group_id>, @res[0]<member_id>).hash<cnt>;
  return UnknownError.new: message => 'User is already a member of that group'
    if $already-exists > 0;
  
  my $db = db.db;
  my $success = False;
  $db.begin;

  try {
    CATCH { default {
      $db.rollback;
      return UnknownError.new: message => $_.Str;
    } };
    my $s1 = $db.prepare($sql-i);
    my $s2 = $db.prepare($sql-d);

    $s1.execute(@res[0]<group_id>, @res[0]<member_id>, @res[0]<role>);
    $s2.execute(@res[0]<group_id>, @res[0]<member_id>, DateTime.now.posix);

    $db.commit;

    $success = True;
  }
  
  $db.finish;
  $success ?? Success.new !! UnknownError.new;
}

sub pending-invites-groups(Int:D $user-id --> Result) is export {
  constant $sql = q:to/EOS/;
    SELECT DISTINCT g.username as name, oi.role
    FROM org_invites oi
    LEFT JOIN users g
           ON g.user_id = oi.group_id
          AND g.password = '-'
    WHERE oi.member_id = (
            SELECT user_id
            FROM users
            WHERE user_id = $1
              AND password <> '-'
            LIMIT 1)
      AND expires >= $2
   GROUP BY username, role;
  EOS

  GroupListing.new: payload => db.query($sql, $user-id, DateTime.now.posix).hashes;
}

sub members-groups(QGroup:D $qg --> Result) is export {
  constant $sql = q:to/EOS/;
    SELECT u.username, gm.role
    FROM group_members gm
    LEFT JOIN users u
      ON u.user_id = gm.member_id
    LEFT JOIN users g
      ON gm.group_id = g.user_id
    WHERE g.username = $1;
  EOS

  GroupListing.new: response-key => 'members', payload => db.query($sql, $qg.group).hashes.List;
}

sub update-meta-groups(QGroupMeta:D $qg, Int:D $user-id --> Result) is export {
  return InsufficientRole.new unless is-group-admin($qg.group, $user-id);

  constant $sql-umid = q:to/EOS/;
    SELECT user_meta_id
    FROM user_meta
    WHERE user_id = $1
      AND key = $2;
  EOS
  constant $sql-ins = q:to/EOS/;
    INSERT INTO user_meta (user_id, key, value)
                   VALUES ($1,      $2,  $3);
  EOS
  constant $sql-upd = q:to/EOS/;
    UPDATE user_meta
    SET value = $1
    WHERE user_meta_id = $2;
  EOS
  constant $sql-del = q:to/EOS/;
    DELETE FROM user_meta
    WHERE user_meta_id = $1;
  EOS
  
  my $db = db.db;
  $db.begin;

  my $search = $db.prepare($sql-umid);
  my $insert = $db.prepare($sql-ins);
  my $update = $db.prepare($sql-upd);
  my $delete = $db.prepare($sql-del);

  my $guid = group-name-to-id($qg.group);
  return NotFound.new unless $guid.defined;

  my $ok = True;
  my ($dt, $val);
  try {
    CATCH { default { $ok = False; $db.rollback; } };
    for qw<email name website> -> $k {
      $val = $qg."$k"();
      next unless $val.defined;
      $dt  = $search.execute($guid, $k).hash;
      if $val eq '' {
        $delete.execute($dt<user_meta_id>);
        next;
      }
      if $dt && $dt<user_meta_id> {
        $update.execute($val, $dt<user_meta_id>);
      } else {
        $insert.execute($guid, $k, $val);
      }
    }
    $db.commit;
  };
  
  $db.finish;

  return UnknownError.new unless $ok;

  Success.new;
}

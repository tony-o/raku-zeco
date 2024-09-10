unit module Zeco::Query::Groups;

use Mailgun;
use Net::DNS;

use Zeco::DB;
use Zeco::Email;
use Zeco::Responses;
use Zeco::Query;
use Zeco::Util::Types;

=begin POD
=NAME
Zeco::Query::Groups

=begin SYNOPSIS
Methods for handling the processes around group management.
=end SYNOPSIS

=head2 method group-name-to-id(Str:D --> Int)

  Signature: Str:D - group name to search for
  Returns: Int - undefined Int if group was not found, otherwise the
           group id to use when performing operations with the group
           name.

  Convenience method, not for use outside of Zeco::Query::*

=head2 method group-exists(Str:D --> Bool:D)

  Signature: Str:D - group name to search for
  Returns: Bool:D - True if group is found, else False

  Convenience method, not for use outside of Zeco::Query::*

=head2 method is-group-admin(Str:D, Int:D --> Bool:D) 

  Signature: Str:D - group name to check
             Int:D - the user id to check for admin role
  Returns: Bool:D - True if the user id given has the admin role for the group

  Convenience method, not for use outside of Zeco::Query::*

=head2 method create-group(QCreateGroup, Int:D --> Result)

  Signature: QCreateGroup - the group to create
             Int:D - the user id creating the group
  Returns: Result

  Checks:
  - Checks if the group exists -> GroupExists 
  - Email domain has MX records -> InvalidEmail
  
  Creates an entry in the `users` table with password '-' (indicating a group).
  Adds the user as an admin to the created group.

=head2 modify-group(QGroupUserRole:D, Int:D --> Result)

  Signature: QGroupUserRole - the new role information containing:
                              - user email to change roles for
                              - the group name to alter roles in
             Int:D - the user id requesting the change, must be an admin
  Returns: Result

  Use this method to alter user roles.

=head2 list-groups(Int:D --> Result) 
  
  Signature: Int:D - authenticated user id to list groups for
  Returns: Result - list of groups the user belongs to

  Returns a string list of the groups the user belongs to.

=head2 leave-group(QGroup:D, Int:D --> Result) 
  
  Signature: QGroup - the group information to leave
             Int:D - authenticated user id of the user leaving the group
  Returns: Result

  Removes any roles associated with the current user and group.

=head2 invite-groups(QGroupUserRole:D, Int:D --> Result) 

  Signature: QGroupUserRole - the group information containing
                              - invited user's email
                              - group name
                              - the user's role
             Int:D - authenticated user id of the user making the request.
                     this user must be an admin.
  Returns: Result

  Makes a group invite for a user to accept or reject.

=head2 accept-invite-groups(QGroup:D, Int:D --> Result) 

  Signature: QGroup - group information the user is accepting an invite for
             Int:D  - authenticated user id accepting the invite
  Returns: Result - list of groups the user belongs to

  Modifies a group invite to a user role.

=head2 pending-invites-groups(Int:D --> Result) 

  Signature: Int:D  - authenticated user id to retrieve invites for
  Returns: Result - list of invites the user may accept

  Lists group invites for the given user.

=head2 members-groups(QGroup:D --> Result) 

  Signature: QGroup - the group to list members of 
  Returns: Result - list of group members

  Lists group members and roles for a given group. All group information
  is intended as public.

=head2 update-meta-groups(QGroupMeta:D, Int:D --> Result)

  Signature: QGroupMeta - the valid meta data fields that can be updated
             Int:D - user id making the request.  must be an admin
  Returns: Result

  Updates the group's public meta data.

=end POD

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
    SELECT count(*) as c FROM users WHERE username = $1 LIMIT 1;
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
    if !$result || !$result<user_id> {
      $d.rollback;
      $d.finish;
      return UnknownError.new;
    }

    $result = $s2.execute($result<user_id>, $user-id, 'admin').hash;

    if $result && $result<role> eq 'admin' {
      $d.commit;
    } else {
      $d.rollback;
    }
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
    :text("Your role in '{$qg.group}' has been changed to: {$qg.role}"),
  ));
  return SuccessFail.new if $mesult<message> ne email-success-message; 

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
  return SuccessFail.new if $mesult<message> ne email-success-message; 
  
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

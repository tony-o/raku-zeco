unit module Zeco::Util::Types;

use Zeco::Util::Json;

=begin pod

=title Zeco::Util::Types

=begin SYNOPSIS
This module contains all valid types to be used in conjunction with the 
middleware outlined in Zeco::Util::Middleware.
=end SYNOPSIS

=end pod

class QError is export {
  has Str $.error is rw;

  method error() { $!error; }
}

role QType is export {
  method !check-field(%in, --> Bool) {
    my %expects = self.^attributes.map({S/^\$('.'|'!')// given $_.name}).map({$_ => 1});
    return False if %in.keys > %expects.keys;
    for %in.keys -> $k {
      return False unless %expects{$k};
    }
    True
  }
  method from-qs(%qs --> QType:D) {
    my %params = [%qs.keys, |self.^attributes.map({S/^\$('.'|'!')// given $_.name})]
      .map({
        $_ => %qs{$_}//Any;
      }).grep(*.value.defined) // ();
    my $obj;
    try {
      $obj = self.new(|%params);
    };
    return $obj if $obj ~~ QType && self!check-field(%params);
    QError.new(
      error => self.error-str(True, :params(%(|%params, |%qs))), 
    ) does QType;
  }

  method from-form($content --> QType:D) {
    my %params = [self.^attributes.map({S/^\$('.'|'!')// given $_.name})]
      .map({
        $_ => try { $content.{$_}.<body> }//Any;
      }).grep(*.value.defined) // ();
    my $obj;
    try {
      $obj = self.new(|%params);
    };
    return $obj if $obj ~~ QType && self!check-field(%params);
    QError.new(
      error => 'Invalid',
    ) does QType;
  }

  method from-body($b is copy --> QType:D) {
    $b = $b ~~ Str ?? $b !! $b.decode;
    my %json   = try { from-j($b) } if $b ne '';
    my %params = [|%json.keys, self.^attributes.map({S/^\$('.'|'!')// given $_.name})]
      .map({
        $_ => %json{$_}//Any;
      }).grep(*.value.defined) // ();
    my $obj;
    try {
      $obj = self.new(|%params);
    };
    return $obj if $obj ~~ QType && self!check-field(%params);
    QError.new(
      error => self.error-str(:params(%(|%params, |%json))),
    ) does QType;
  }

  method error-str(Bool:D $qs = False, :%params = {} --> Str:D) is export {
    sprintf 'Expected %s attributes: %s%s%s',
            $qs ?? 'query' !! 'json body',
            self.^attributes.map({S/^\$('.'|'!')// given $_.name}).join(', '),
            %params.keys ?? '. Got: ' !! '',
            %params.keys.sort.map({"{$_}={%params{$_}//'_unset_'}"}).join(', ')
            ;
  }
}

class QInitPasswordReset does QType is export {
  has Str $.auth;

  submethod BUILD(Str:D :$!auth) { }
}

class QUpdateUserMeta does QType is export {
  has Str $.email;
  has Str $.name;
  has Str $.website;

  submethod BUILD(Str :$!email , Str :$!name , Str :$!website) { }
}

class QLogin does QType is export {
  has Str $.username;
  has Str $.password;

  submethod BUILD(Str:D :$!username, Str:D :$!password) { }
}

class QPasswordReset does QType is export {
  has Str $.auth;
  has Str $.key;
  has Str $.password;

  submethod BUILD(Str:D :$!auth, Str:D :$!password, Str:D :$!key) { }
}

class QRegister does QType is export {
  has Str $.email;
  has Str $.username;
  has Str $.password;

  submethod BUILD(Str:D :$!email, Str:D :$!password, Str:D :$!username) { }
}

class QCreateGroup does QType is export {
  has Str $.email;
  has Str $.group;

  submethod BUILD(
    Str:D :$!email
      where {$_ ~~ m/^<+[a..zA..Z0..9\.!#$%&'\*\+\\\/\=\?\^\_`\{\|\}\~\-]>+'@'<+[a..zA..Z0..9\-]> ** 1..61 '.' <+[a..zA..Z]> ** 2..6$/ },
    Str:D :$!group,
  ) { }
};

class QGroupUserRole does QType is export {
  has Str $.user;
  has Str $.group;
  has Str $.role;
  submethod BUILD(Str:D :$!group, Str:D :$!user, Str:D :$!role) { }
};

class QGroup does QType is export {
  has Str $.group;
  submethod BUILD(Str:D :$!group) { }
}

class QGroupMeta does QType is export {
  has Str $.email;
  has Str $.name;
  has Str $.website;

  has Str $.group;

  submethod BUILD(:$!email = Str, :$!name = Str, :$!website = Str, Str :$org = Str, Str :$!group = Str) {
    die unless $!group.defined ?^ $org.defined;
    $!group = $!group // $org;
  }
}

class QIngestUpload does QType is export {
  has Buf $.dist;

  submethod BUILD(Buf:D :$!dist) { }
  method from-body(Buf() $bs) {
    QIngestUpload.new: dist => $bs;
  }
}

class QRemoveDist does QType is export {
  has Str $.dist;

  submethod BUILD(Str:D :$!dist) { }
}

class QEmail is export {
  has Str $.to;
  has Str $.type;
  has Str $.id;

  submethod BUILD(Str:D :$!to, Str:D :$!type where * ~~ 'PASSWORD-RESET'|'INVITE-GROUP'|'MODIFY-GROUP', Str:D :$!id) {}
}

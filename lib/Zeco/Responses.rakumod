unit module Zeco::Responses;

use Zeco::Util::Json;
use Zeco::Util::BST;

=begin pod

=NAME
Zeco::Responses

=begin SYNOPSIS
Contains typed responses for use in method chaining or serializing to JSON for
web responses.
=end SYNOPSIS

=head2 class Result 

  This class is used as a base for other messages and only intended for use
  when all members are provided or the defaults are appropriate. Inheriting
  classes may override the render mechanism, provide their own members, and
  provide other interfaces to assist in method chaining, testing, or provide
  other usability mechanisms.

  Members:
    Str  :message ()      - generic string message
    Bool :success (False) - indicates whether the message is a success message
    Int  :status  (500)   - response status
 
    method render(Response --> Nil)

    Signature: Response - hummingbird response object to serialize the class to


=end pod

role Result is export {
  has Str  $.message;
  has Bool $.success = False;
  has Int  $.status  = 500;

  method render($res) {
    $res.status($!success && $!status >= 200 && $!status < 300 ?? 200 !! $!status)
        .json(to-j({ :$!success, ($!message ne '' ?? :$!message !! ()) }));
    $res;
  }
}

class GroupExists does Result is export {
  submethod BUILD (:$!message = 'Group or username already exists.',
                   :$!success = False,
                   :$!status  = 422) {}
}

class InvalidEmail does Result is export {
  submethod BUILD (:$!message = 'Invalid email.',
                   :$!success = False,
                   :$!status  = 422) {}
}

class UnknownError does Result is export {
  submethod BUILD (:$!message = 'Unknown error.',
                   :$!success = False,
                   :$!status  = 500) {}
}

class Unauthorized does Result is export {
  submethod BUILD (:$!message = 'No AUTHORIZATION header supplied or is invalid.',
                   :$!success = False,
                   :$!status  = 401) {}
}

class InsufficientRole does Result is export {
  submethod BUILD (:$!message = 'You must be an admin to perform this action.',
                   :$!success = False,
                   :$!status  = 403) {}
}

class NotFound does Result is export {
  submethod BUILD (:$!message = 'Not found.',
                   :$!success = False,
                   :$!status  = 404) {}
}

class ExistingGroupMember does Result is export {
 submethod BUILD (:$!message = 'User is already a member of group.',
                  :$!success = False,
                  :$!status  = 422) {}
} 

class UnableToExtractArchive does Result is export {
  submethod BUILD (:$!message = 'Unable to extract archive',
                   :$!success = False,
                   :$!status  = 422) {}
}

class UnableToLocateMeta6 does Result is export {
  submethod BUILD (:$!message = 'Unable to locate META6.json. Was not found in root archive and root directory does not contain exactly one directory, refusing to proceed',
                   :$!success = False,
                   :$!status  = 422) {}
}

class InvalidAuth does Result is export {
  submethod BUILD (:$!message = "Invalid auth",
                   :$!success = False,
                   :$!status  = 403) {}
}

class InvalidMeta6Json does Result is export {
  submethod BUILD (:$!message = 'Unable to parse META6.json',
                   :$!success = False,
                   :$!status  = 422) {}
}

class Success does Result is export {
  submethod BUILD (:$!message = '',
                   :$!success = True,
                   :$!status  = 200) {}
}

class SuccessAuth does Result is export {
  has $!key;
  submethod BUILD (:$!key) {}
}

class InvalidPassword does Result is export {
  submethod BUILD (:$!message = "Password must be >={InvalidPassword.MIN_LEN} characters.",
                   :$!success = False,
                   :$!status  = 400) {}
  method MIN_LEN { 8 }
}

class UsernameExists does Result is export {
  submethod BUILD (:$!message = 'Username exists, please choose another or initiate a password reset.',
                   :$!success = False,
                   :$!status  = 400) {}
}
class EmailExists does Result is export {
  submethod BUILD (:$!message = 'Email exists, please initiate a password reset.',
                   :$!success = False,
                   :$!status  = 400) {}
}

class SuccessHashPayload does Result is export {
  has %!json;
  submethod BUILD (:%!json,
                   :$!status = 200,
                   :$!success = True) { }
  method render($res) {
    $res.status(200)
        .json(to-j({:success, |%!json }));
    $res;
  }
}

class SuccessFail does Result is export {
  submethod BUILD (:$!message = 'Operation partially successful but no email was sent. You may want to reach out the old fashioned way.',
                   :$!success = True,
                   :$!status  = 200) {}
}

class GroupListing does Result is export {
  has @!payload;
  has Str $!response-key;
  submethod BUILD (:@!payload, :$!response-key = 'groups', :$!status = 200) { }
  method render($res) {
    $res.status(200)
        .json(to-j({:success, $!response-key => @!payload}));
    $res;
  }
  method payload() { @!payload }
}

class MetaIndex does Result is export {
  has @!index;

  submethod BUILD (:@!index, :$!status = 200) { }
  method render($res, :$bin = False) {
    $res.status($!status);
    if ($bin) {
      my Buf $idx = index(@!index).serialize;
      $res.write($idx);
    } else {
      $res.json(to-j(@!index));
    }
    $res;
  }
  method index() { @!index; }
}

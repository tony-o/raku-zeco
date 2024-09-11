unit module Zeco::Email;

use Zeco::Config;
use Zeco::Util::Types;
use Zeco::Util::Process;

=begin POD
=NAME
Zeco::Email

=begin SYNOPSIS
Contains an shorter interface for sending emails from the server. Will run the
command provided in config.email-command
=end SYNOPSIS

=head2 method send-message (QEmail --> Int)

  Signature: QEmail - contains the email info.
  Returns: Return code from process

  Calling this method will create and call a command as specified from
  config.email-command as:

  <cmd> "<QEmail.to>" "<QEmail.type>" "<QEmail.id>"

  The type to database id mapping is as follows:

  PASSWORD-RESET     password_reset.password_reset_id 

=end POD

sub send-message(QEmail $msg --> Int) is export {
  my ($rc, ) = proc(|config.email-command, $msg.to, $msg.type, $msg.id);
  return $rc; 
}

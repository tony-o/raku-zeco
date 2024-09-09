unit module Zeco::Email;

use Zeco::Config;
use Mailgun;


=begin POD
=NAME
Zeco::Email

=begin SYNOPSIS
Contains an shorter interface for sending emails from the server.  Currently
configured to use the mailgun API.  Message below refers to the
Message provided by dist Mailgun.
=end SYNOPSIS

=head2 method send-message (Message --> Hash)

  Signature: Message - contains the email info.
  Returns: Hash containing success or error data from mailgun.

=head2 method message (*% --> Message)

  Signature: *% - takes keys <from to subject text html> and formats that
                  data into a Message for use with Mailgun
  Returns: Message

=head2 method email-success-message

  Returns: Str containing the string Mailgun API returns when a message was
           sent successfully.

=end POD

constant \env = config.email-key;
my $client = Client.new(
  :domain(%*ENV<ZEFECO_DOMAIN>//'zef.pm'),
  :api-key(env),
);

my $message-templ = Message.new(
  :from<no-reply@zef.pm>,
).defaults;

sub send-message(Message $msg --> Hash) is export {
  if env eq 'unset' {
    return {:message(email-success-message)};
  }

  $client.send($msg);
}

sub message(*%v --> Message) is export { $message-templ.(|%v) }
sub email-success-message is export {'Queued. Thank you.'};

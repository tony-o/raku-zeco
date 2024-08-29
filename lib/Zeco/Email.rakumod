unit module Zeco::Email;

use Zeco::Config;
use Mailgun;

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
    return {:message('Queued. Thank you.')};
  }

  $client.send($msg);
}

sub message(*%v --> Message) is export { $message-templ.(|%v) }

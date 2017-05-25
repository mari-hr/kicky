use strict;
use warnings;
use v5.14;

package Kicky;
use base 'GGWP::Base';

our $VERSION = '0.01';

=head1 NAME

Kicky - Kick-ass message delivery to end users

=head1 DESCRIPTION

=cut

# db
#  consumers
#   platform
#   token
#   info: json, lang, name, nick, ...
#   topics: array
#   flags: array
#  flags
#   id
#   name
#   title: json, multilang
#   description: json, multilang
#  email_templates
#   id
#   name
#   title
#   content
#
# api
#   /send/
#       platforms
#       payload
#
#       token
#       -or
#       topics
#       flags
#
# queues
#   kicky-fetcher
#   kicky-pushes-<platform>
#
# platforms:
#  email
#  gcm
#  apns
#  facebook
#  viber
#  sms
#
# modules
#   sender
#   sender::<platform>
#
# cli
#   kicky-cli
#   kicky-fetcher
#   kicky-sender-<platform>

=head1 AUTHOR

Ruslan Zakirov E<lt>ruslan.zakirov@gmail.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;

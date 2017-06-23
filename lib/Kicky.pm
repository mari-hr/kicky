use strict;
use warnings;
use v5.14;

package Kicky;
use base 'Yasen', 'Kicky::Base';

our $VERSION = '0.01';

use Kicky::Request;

=head1 NAME

Kicky - Kick-ass message delivery to end users

=head1 DESCRIPTION

=cut

# db
#  recipients
#   platform
#   token
#   lang
#   user_id: !?
#   topics: array
#   flags: array
#  flags
#   id
#   name
#   title: json, multilang
#   description: json, multilang
#  mail_templates
#   id
#   name: keyword used in APIs
#   title: string in interface
#   subject: json, multilang
#   content: json, multilang
#
# api
#   /send/
#       platform
#       payload
#
#       token
#       -or
#       topics
#       flags
#
# exchanges
#   kicky_requests: fanout
#   kicky_pushes_<platform>
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

sub routes {
    my $self = shift;
    return (
        {
            path => '/api/v1/send',
            controller => 'Kicky::API',
            methods => {
                POST => {
                    action => 'send_push',
                },
            },
        }
    );
}

=head1 AUTHOR

Ruslan Zakirov E<lt>ruslan.zakirov@gmail.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;

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

=head1 CONFIGURATION

You configure Kicky using a JSON file. Most command line tools take "-c <file>"
option, psgi application takes path via ENV variable "KICKY_CONFIG".

=head2 mail

    {
        ...
        "mail": {
            "sendmail_path": "/usr/sbin/sendmail",
            "sendmail_args": ["-XV", "-f", "bounces", "-t"]
        }
        ...
    }

Mail subsection has the following keys:

=over 4

=item sendmail_path (string, B<required>)

Absolute path to sendmail binary.

=item sendmail_args (array of strings, B<optional>)

Array of additional arguments that are passed to sendmail.
Most probably you need '-t'.

=back

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

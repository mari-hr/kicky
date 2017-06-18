use strict;
use warnings;

package Kicky::API;
use base 'Kicky::Base';

=head2 send_mail

    POST /api/v1/mail/send
    Content-Type: application/json

    {
        "recipient": {}
        "template": {
            "name": "template name",
            "payload": {...},
        },
    }

    {
        "platform": "mail",
        "token": "ruz@sport.ru",
        "template": {
            "name": "wellcome",
            "payload": {...},
        },
    }

=cut

# exchanges
# kicky_requests -> (manager) -> kicky_pushes_*


sub send_push {
    my $self = shift;
    my $args = shift;

    $self->rabbit
    ->then(cb_w_context {
        my $r = shift;
        $r->publish(
            exchange => 'kicky_requests',
            body => $self->json->encode($args),
        );
    });
    return $self->simple_psgi_response(json => { data => {} });
}

1;

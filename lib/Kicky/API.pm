use strict;
use warnings;

package Kicky::API;
use base 'Kicky::Base';

use Async::ContextSwitcher;

=head2 send_push

    POST /api/v1/send
    Content-Type: application/json

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

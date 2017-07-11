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
        $self->log->debug('Connected to rabbit, publishing request');
        return $r->publish(
            exchange => 'kicky_requests',
            body => $self->json->encode($args),
        );
    })
    ->then(cb_w_context {
        $self->log->debug('Published request');
        return $self->simple_psgi_response(json => { data => {} });
    })
    ->catch(cb_w_context {
        return $self->simple_psgi_response(503, json => {});
    });
}

1;

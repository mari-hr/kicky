use strict;
use warnings;
use v5.14;

package Kicky::Manager;
use base 'Kicky::Base';

use Async::ContextSwitcher;

sub setup_listener {
    my $self = shift;

    $self->log->debug("Starting up listener");

    state $r;
    $self->rabbit
    ->then(cb_w_context {
        $r = shift;
        return $r->consume(
            queue => 'kicky_manager',
            tag => 'kicky-manager-'. $$,
            cb => cb_w_context {
                my $m = shift;
                $self->ctx->new;
                $self->log->debug("A new request");
                $self->process_request($m);
            },
            no_ack => 1,
        );
    })
    ->then( cb_w_context {
        $self->log->info("Subscribed to commands queue");
    })
    ->catch(cb_w_context {
        die @_;
    });
}

sub process_request {
    my $self = shift;
    my $m = shift;

    my $payload = $m->{body}{payload};
    my $json = $self->json;
    my $data = $json->decode( $payload );

    my $platform = $data->{platform};
    unless ( $platform ) {
        $self->log->error("message has no platform");
        return;
    }
    $self->log->debug("Platform '$platform'");

    my @tokens;
    if ( $data->{token} ) {
        delete $data->{token};
        push @tokens, $data->{token};
    }
    elsif ( $data->{topics} && $data->{flags} ) {
        die "not yet implemented"
    }
    else {
        die "wrong data"
    }

    $self->rabbit
    ->then(cb_w_context {
        my $r = shift;
        foreach my $token ( @tokens ) {
            $r->publish(
                exchange => 'kicky_pushes_'. $platform,

                body => $json->encode({ %$data, tokens => [$token] }),
            );
        }
    });
}

1;

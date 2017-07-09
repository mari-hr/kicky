use strict;
use warnings;
use v5.14;

package Kicky::Sender;
use base 'Kicky::Base';

use Async::ContextSwitcher;
use Kicky::Payload;
use Carp qw(confess);
use Promises qw(collect);

sub init {
    my $self = shift;
    my $platform = $self->{platform} or confess("no platform");
    my $class = 'Kicky::Sender::'. ucfirst( lc $platform );
    eval "require $class; 1"
        or confess("Couldn't load '$platform' sender ($class): $@");

    $self = bless $self, $class;
    return $self;
}

sub platform { return $_[0]->{platform} }

sub payload_provider {
    my $self = shift;
    return $self->{payload_provider} ||= Kicky::Payload->new(
        app => $self->app,
        platform => $self->platform,
    );
}

sub setup_listener {
    my $self = shift;

    $self->log->debug("Starting up listener");

    state $r;
    $self->rabbit
    ->then(cb_w_context {
        $r = shift;
        return $r->consume(
            queue => 'kicky_sender_'. $self->platform,
            tag => 'kicky-sender-'. $$,
            cb => cb_w_context {
                my $m = shift;
                $self->ctx->new;
                $self->log->debug("A new mail push");
                $self->process_message($m);
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

sub process_message {
    my $self = shift;
    my $m = shift;
    my $payload = $m->{body}{payload};
    my $data = $self->json->decode( $payload );
    my $provider = $self->payload_provider;
    return $provider->fetch($data)
    ->then(cb_w_context {
        my @p;
        foreach my $token ( @{ $data->{recipients} } ) {
            my $rendered = $provider->process($data, $token);
            push @p, $self->send( %$rendered, to => $token );
        }
        return collect(@p);
    })
    ->then(cb_w_context {
        $self->log->debug("processed push");
    })
    ->catch(cb_w_context{
        $self->log->error("Couldn't process a request: ". $self->dump(\@_));
    });
}

1;

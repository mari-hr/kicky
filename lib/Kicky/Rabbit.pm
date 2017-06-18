use strict;
use warnings;
use v5.16;

package Kicky::Rabbit;
use base 'Kicky::Base';

__PACKAGE__->register_exceptions(
    'no_connection' => {
        message => 'Internal server error',
        status => 500,
        to => 'rabbit',
    },
);

use Promises qw(deferred);
use Async::ContextSwitcher;
use AnyEvent::RabbitMQ;

our $AR = AnyEvent::RabbitMQ->new( verbose => 0 )->load_xml_spec;

sub init {
    my $self = shift;
    $self->connect;
    return $self;
}

sub connect {
    my $self = shift;

    state $connected;
    state $connecting;

    return deferred->resolve($AR)->promise if $connected;

    state @d;
    push @d, deferred;
    return $d[-1]->promise if $connecting;

    $connecting = 1;

    $AR->connect(
        host       => 'localhost',
        port       => 5672,
        user       => 'guest',
        pass       => 'guest',
        vhost      => '/',
        timeout    => 1,
        on_success => sub {
            $connected = 1; $connecting = 0;
            $_->resolve( @_ ) foreach @d;
        },
        on_failure => sub {
            $connected = 0; $connecting = 0;
            my $err = $self->exception('no_connection', more => [@_]);
            $_->reject( $err ) foreach @d;
        },
        on_read_failure => sub { die "read: ". join ' ', @_ },
        on_return  => sub {
            my $frame = shift;
            die "Unable to deliver: ". Dumper($frame);
        },
        on_close   => sub {
            $connected = 0; $connecting = 0;
            my $why = shift;
            use Data::Dumper;
            print STDERR Dumper($why);
            if (ref($why)) {
                my $method_frame = $why->method_frame;
                die "close: " . $method_frame->reply_code .": ". $method_frame->reply_text;
            }
            else {
                die "close: $why";
            }
        },
    );

    $d[-1]->promise;
}

sub channel {
    my $self = shift;

    return $self->connect
    ->then( cb_w_context {
        my $ar = shift;

        my $d = deferred;
        $ar->open_channel(
            on_success => sub {
                $d->resolve( Kicky::Rabbit::Channel->new( c => shift ) );
            },
            on_failure => sub {
                $d->reject( "Channel: ", @_ )
            },
            on_close   => sub {
                use Data::Dumper;
                print STDERR Dumper(\@_);
                my $method_frame = shift->method_frame;
                die $method_frame->reply_code, $method_frame->reply_text;
            },
        );
        return $d->promise;
    });
}

package Kicky::Rabbit::Channel;
use base 'Kicky::Base';
use Promises qw(deferred);

sub exchange {
    my $self = shift;
    my %args = @_;

    my ($name, $exchange, $key) = delete @args{qw(name exchange routing_key)};

    my $d = deferred;
    $self->{c}->declare_exchange(
        %args,
        exchange => $name,
        on_success => sub {
            return $d->resolve( $name ) unless $exchange;

            $self->{c}->bind_exchange(
                source => $exchange,
                destination => $name,
                routing_key => $key,
                on_success => sub { $d->resolve( $name ) },
                on_failure => sub { $d->reject(@_) },
            );
        },
        on_failure => sub { $d->reject("Exchange: ", @_) },
    );
    return $d->promise;
}

sub queue {
    my $self = shift;
    my %args = @_;

    my ($name, $exchange, $key) = delete @args{qw(name exchange routing_key)};

    my $d = deferred;
    $self->{c}->declare_queue(
        durable => 1,
        no_ack => 0,
        %args,
        queue => $name,
        on_success => sub {
            my $name = shift()->method_frame->queue;
            return $d->resolve( $name ) unless $exchange;

            $self->{c}->bind_queue(
                queue => $name,
                exchange => $exchange,
                routing_key => $key,
                on_success => sub { $d->resolve( $name ) },
                on_failure => sub { $d->reject(@_) },
            );
        },
        on_failure => sub { $d->reject(@_) },
    );
    return $d->promise;
}

sub publish {
    my $self = shift;
    my %args = ( @_ );

    my $d = deferred;
    $self->{c}->publish(
        %args,
        no_ack => 0,
        on_ack => sub { $d->resolve( @_ ) },
        on_nack => sub { $d->reject( @_ ) },
    );
    return $d->promise;
}

sub consume {
    my $self = shift;
    my %args = @_;
    my $d = deferred;
    $self->{c}->consume(
        queue => $args{queue},
        consumer_tag => $args{tag},
        on_consume => sub {
            my $m = shift;
            my $info = $m->{deliver}->method_frame;
            $self->log->debug( 'Message on '. $info->exchange .' exchange, key '. $info->routing_key );
            return $args{cb}->( $m );
        },
        on_cancel => sub {
            return if $_[0]->method_frame->isa('Net::AMQP::Protocol::Basic::CancelOk');
            die "Consumption canceled: ". $self->dump( \@_ );
        },
        on_success => sub { $d->resolve; },
        on_failure => sub { $d->reject( @_ ); },
        no_ack => 1,
    );
    return $d->promise;
}


sub cancel {
    my $self = shift;
    my $tag = shift;

    my $d = deferred;
    $self->{c}->cancel(
        consumer_tag => $tag,
        on_success => sub { $d->resolve; },
        on_failure => sub { $d->reject( @_ ); },
    );
    return $d->promise;
}

sub setup {
    my $self = shift;

    $self->setup_exchange(
        name => 'kicky_requests',
        type => 'fanout',
        durable => 1,
    );

    $self->setup_queue(
        name => 'kicky_manager',
        exchange => 'kicky_requests',
        durable => 1,
    );

    foreach my $platform (qw(mail gcm apns facebook)) {
        $self->setup_exchange(
            name => 'kicky_pushes_'. $platform,
            type => 'fanout',
            durable => 1,
        );

        $self->setup_queue(
            name => 'kicky_sender_'. $platform,
            exchange => 'kicky_pushes_'. $platform,
            durable => 1,
        );
    }

}

sub setup_exchange {
    my $self = shift;
    $self->_setup_object('exchange', @_);
}

sub setup_queue {
    my $self = shift;
    $self->_setup_object('queue', @_);
}

sub _setup_object {
    my $self = shift;
    my $method = shift;
    my %args = (@_);

    my $cv = AnyEvent->condvar;

    return $self->$method( %args )
    ->then(sub { $self->log->debug("Created $method '$args{name}'")})
    ->catch(sub {
        $self->log->error("Something went wrong: @_");
    })
    ->finally(sub { $cv->send });

    $cv->recv;
}

1;

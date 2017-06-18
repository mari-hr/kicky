use strict;
use warnings;
use v5.16;

package Kicky::Base;
use base 'Yasen::Base';

use DBIx::Poggy;
use Japster::Exception;
use JSON::XS qw();
use Promises backend => ['AnyEvent'];
use AnyEvent;
use Async::ContextSwitcher qw(context cb_w_context);
use Scalar::Util qw(refaddr);

sub api {
    require Kicky::API;
    return state $api = Kicky::API->new;
}

our $pool;
sub db {
    return $pool if $pool;

    my $self = shift;
    my $cfg = $self->app->config->{db};
    $cfg->{connection_arguments} ||= {};
    $cfg->{connection_arguments}{HandleError} = sub { $_[0]=Carp::longmess($_[0]); 0; };
    $pool = DBIx::Poggy->new;
    $pool->connect('dbi:Pg:db='. $cfg->{name}, $cfg->{user}, $cfg->{password}, $cfg->{connection_arguments});
    return $pool;
}

sub rabbit {
    require Kicky::Rabbit;
    state $r = Kicky::Rabbit->new;
    return $r->channel;
}

sub setup_db {
    my $self = shift;
    my $data = shift;

    use Kicky::Model::MailTemplate;
    foreach my $mt ( @{ $data->{'mail-templates'} || []}) {
        my $cv = AnyEvent->condvar;
        Kicky::Model::MailTemplate->create( dbh => $self->db->take, %$mt )
            ->catch(sub { $self->log->error("failed to create template: @_") })
            ->finally($cv);
        $cv->recv;
    }
    return;
}

1;

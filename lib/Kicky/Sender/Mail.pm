use strict;
use warnings;
use v5.14;

package Kicky::Sender::Mail;
use base 'Kicky::Sender';

use MIME::Entity;
use Promises qw(deferred);
use Carp qw(confess);

sub send {
    my $self = shift;
    my %args = (
        subject => undef,
        to => undef,
        content => undef,
        @_
    );

    my $entity = MIME::Entity->build(
        Type => 'text/html',
        To => $args{to},
        Subject => $args{subject},
        Data => [$args{content}],
    );

    return $self->run(
        entity => $entity,
    );
}

sub run {
    my $self = shift;
    my %args = (
        entity => undef,
        @_
    );

    my $cfg = $self->config->{mail};
    my $cmd = $cfg->{sendmail_path}
        or confess("No 'sendmail_path' in the config");
    my @args = (@{$cfg->{sendmail_args}||[]});

    open my $h, '|-', $cmd, @args
        or die "Couldn't exec '$cmd': $!";
    $args{entity}->print( $h );
    close $h;

    return deferred->resolve->promise;
}

1;

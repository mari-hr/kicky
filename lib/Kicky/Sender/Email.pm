use strict;
use warnings;
use v5.14;

package Kicky::Sender::Email;
use MIME::Entity;
use Promises qw(deferred);

sub send {
    my $self = shift;
    my %args = (
        subject => undef,
        to => undef,
        body => undef,
        @_
    );

    my $entity = MIME::Entity->build(
        Type => 'text/html',
        To => $args{to},
        Subject => $args{subject},
        Data => [$args{body}],
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

    my $cfg = $self->config->{email};
    my $cmd = $cfg->{sendmail_path} || confess("No path");

    open my $h, '|-', $cmd, @args
        or die "Couldn't exec '$cmd': $!";
    $args{entity}->print( $h );
    close $h;

    return deferred->resolve->promise;
}

1;

use strict;
use warnings;

package Kicky::Payload;
use base 'Kicky::Base';

use Async::ContextSwitcher;
use Carp qw(confess);

sub init {
    my $self = shift;
    my $platform = $self->{platform} or confess("no platform");
    my $class = 'Kicky::Payload::'. ucfirst( lc $platform );
    eval "require $class; 1"
        or confess("Couldn't load '$platform' sender ($class): $@");

    $self = bless $self, $class;
    return $self;
}

sub platform { return $_[0]->{platform} }

sub process {}

1;

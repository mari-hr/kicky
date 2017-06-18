use strict;
use warnings;
use v5.16;

package Kicky::Model;
use base 'Kicky::Base', 'Plum::Model';

use Async::ContextSwitcher;

__PACKAGE__->register_exceptions(
    'required' => {
        message => 'Required argument is missing',
        status => 400,
    },
    'invalid' => {
        message => 'Invalid value for an argument',
        status => 400,
    },
    'conflict' => {
        message => 'Duplicate value',
        status => 409,
    },
);

sub error_expander {
    my $self = shift;
    my $err = shift;
    die $err unless ref $err;
    if ( $err->{state} eq '23502' ) {
        my ($field) = $err->{errstr} =~ /column "(.*?)" /;
        die $self->exception('required', parameter => $field);
    }
    elsif ( $err->{state} eq '23503' ) {
        my ($field) = $err->{errstr} =~ /Key \((.*?)\)=/;
        die $self->exception('invalid', parameter => $field);
    }
    elsif ( $err->{state} eq '23505' ) {
        my ($field) = $err->{errstr} =~ /Key \((.*?)\)=/;
        $field =~ s/::\w+//g;
        $field =~ s/^\w+\((.+?)\)$/$1/g;
        die $self->exception('conflict', parameter => $field);
    }
    die $err;
}

sub create {
    my $self = shift;
    return $self->SUPER::create(@_)
    ->catch( cb_w_context { $self->error_expander( shift ) });
}

sub _update {
    my $self = shift;
    return $self->SUPER::_update(@_)
    ->catch( cb_w_context { $self->error_expander( shift ) });
}

1;

use strict;
use warnings;
use v5.16;

package Kicky::Resource;
use base 'Japster::Resource', 'Kicky::Base';

use Async::ContextSwitcher;

sub model_class {
    my $self = shift;
    my $class = ref $self || $self;
    $class =~ s/Resource/Model/;
    return $class;
}

sub type {
    my $self = shift;
    my $type = $self->model_class->table;
    $type =~ s/_/-/g;
    return $type;
}

sub load {
    my $self = shift;
    my %args = @_;
    return $self->model_class
    ->simple_find(
        dbh => $self->db->take,
        columns => { id => $args{id} }
    )->then(cb_w_context {
        my $list = shift;
        return shift @$list;
    });
}

sub create {
    my $self = shift;
    my %args = @_;
    return $self->model_class->create( %{ $args{fields} || {} }, dbh => $self->db->take );
}

sub update {
    my $self = shift;
    my %args = @_;
    return $self->model_class->update( %{ $args{fields} }, dbh => $self->db->take );
}

sub remove {
    my $self = shift;
    my %args = @_;
    return $self->model_class->remove( id => $args{id}, dbh => $self->db->take )
    ->then(cb_w_context {
        my $res = shift;
        die $self->exception('not_found') unless $res > 0;
        return ();
    });
}

sub find {
    my $self = shift;
    my %args = @_;
    return $self->model_class->simple_find( dbh => $self->db->take );
}

1;

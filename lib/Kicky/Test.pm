use strict;
use warnings;
use v5.14;

package Kicky::Test;
use Kicky;

use Async::ContextSwitcher;

sub app {
    my $self = shift;
    state $app;
    return $app if $app;

    my $config = { };
    $app = Kicky->new( config => $config );

    $self->bootstrap_db;
    $self->bootstrap_rabbit;

    return $app;
}

sub bootstrap_db {
    my $self = shift;

    $app->config->{db} = {
        name => 'kicky_test',
        user => 'postgres',
        password => undef,
        connection_arguments => {
            PrintError => 0,
            RaiseError => 0,
        },
    };

    return $app->setup->db_schema;
}

sub bootstrap_rabbit {
    $app->setup->rabbit;
}


1;

#!/usr/bin/env perl

use strict;
use warnings;
use constant UWSGI => ($ENV{PLACK_SERVER}||'') eq 'uwsgi';

unless ( caller ) {
    die q{Use the following command for now

    KICKY_CONFIG="xxx.config" plackup -s Twiggy `bin/ggwp-server.psgi`

};
}

if ( UWSGI ) {
    require Coro::AnyEvent;
    require AnyEvent;
}
require Kicky;
my $app = eval { Kicky->new(config_file => $ENV{Kicky_CONFIG}) } or do {
    return Kicky->error_server( $@ ); 
};
return UWSGI? $app->uwsgi_server : $app->psgi_server;

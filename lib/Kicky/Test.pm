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
    $self->bootstrap_db($config);
    $app = Kicky->new( config => $config );

    my $cv = AnyEvent->condvar;
    $app->rabbit->then(cb_w_context { return shift->setup })->finally($cv);
    $cv->recv;

    return $app;
}

sub bootstrap_db {
    my $self = shift;
    my $config = shift;

    my $dbname = 'kicky_test';

    use DBI;
    my $dbh = DBI->connect('dbi:Pg:host=localhost', postgres => undef, { PrintError => 1, RaiseError => 1 }); 
    $dbh->do("DROP DATABASE IF EXISTS $dbname");
    $dbh->do("CREATE DATABASE $dbname");

    $dbh = DBI->connect("dbi:Pg:dbname=$dbname", postgres => undef, { PrintError => 1, RaiseError => 0 }); 
    foreach my $file (qw(schema)) {
        my $sql = do {
            open my $fh, '<', "./schema/$file.sql"
                or die "can not open '$file' schema: $!";
            local $/; <$fh>
        };
        local $SIG{__WARN__} = sub {};
        $dbh->do($sql) or die "failed to create schema: ". $dbh->errstr;
    }

    $config->{db} = {
        name => $dbname,
        user => 'postgres',
        password => undef,
        connection_arguments => {
            PrintError => 0,
            RaiseError => 0,
        },
    };

    return;
}


1;

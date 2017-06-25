use strict;
use warnings;

package Kicky::Setup;
use base 'Kicky::Base';

use Async::ContextSwitcher;

sub db_schema {
    my $self = shift;
    my %args = (
        dba => 'postgres',
        password => undef,
        @_
    );

    my $host = $self->config->{db}{host};
    my $name = $self->config->{db}{name} || 'kicky';

    my $dsn = 'dbi:Pg:';
    $dsn .= "host=$host;" if $host;

    require DBI;
    my $dbh = DBI->connect(
        $dsn, $args{dba}, $args{password},
        { PrintError => 1, RaiseError => 1 }
    );
    $dbh->do("DROP DATABASE IF EXISTS $name");
    $dbh->do("CREATE DATABASE $name");

    $dbh = DBI->connect("${dsn}dbname=$name", postgres => undef, { PrintError => 1, RaiseError => 0 });
    foreach my $file (qw(schema)) {
        my $sql = do {
            open my $fh, '<', "./schema/$file.sql"
                or die "can not open '$file' schema: $!";
            local $/; <$fh>
        };
        local $SIG{__WARN__} = sub {};
        $dbh->do($sql) or die "failed to create schema: ". $dbh->errstr;
    }
    return;
}

sub db_import {
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

sub rabbit {
    my $self = shift;
    my $cv = AnyEvent->condvar;
    $self->app->rabbit->then(cb_w_context { return shift->setup })->finally($cv);
    $cv->recv;
    return;
}


1;

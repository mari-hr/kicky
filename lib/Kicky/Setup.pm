use strict;
use warnings;

package Kicky::Setup;
use base 'Kicky::Base';

use Async::ContextSwitcher;
use Promises qw(collect);

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
    $self->app->rabbit
    ->then(cb_w_context {
        my $r = shift;

        my @p;
        my $exchange = sub {
            push @p, $r->exchange(@_)
                ->then(cb_w_context { $self->log->debug('created an exchange') });
        };
        my $queue = sub {
            push @p, $r->queue(@_)
                ->then(cb_w_context { $self->log->debug('created a queue') });
        };

        $exchange->(
            name => 'kicky_requests',
            type => 'fanout',
            durable => 1,
        );

        $queue->(
            name => 'kicky_manager',
            exchange => 'kicky_requests',
            durable => 1,
        );

        foreach my $platform (qw(mail gcm apns facebook)) {
            $exchange->(
                name => 'kicky_pushes_'. $platform,
                type => 'fanout',
                durable => 1,
            );

            $queue->(
                name => 'kicky_sender_'. $platform,
                exchange => 'kicky_pushes_'. $platform,
                durable => 1,
            );
        }

        return collect(@p);
    })
    ->catch(cb_w_context {
        $self->log->error("Something went wrong: @_");
    })
    ->finally($cv);
    $cv->recv;
    return;
}

1;

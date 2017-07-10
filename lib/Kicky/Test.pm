use strict;
use warnings;
use v5.14;

package Kicky::Test;
use Kicky;

use Async::ContextSwitcher;

our $app;

sub app {
    my $self = shift;
    return $app if $app;

    my $config = { };
    $app = Kicky->new( config => $config );

    $self->bootstrap_db;
    $self->bootstrap_rabbit;
    $self->bootstrap_sendmail;

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

sub bootstrap_sendmail {
    $app->config->{mail} = {
        sendmail_path => "./t/data/sendmail",
        sendmail_args => [qw(-t -f bounces -XV)],
    };
}

sub last_mail {
    open my $fh, "<", 't/tmp/mail.log' or die "$!";
    my @list = do {local $/; grep length, split /%% END MAIL %%\n/, <$fh> };
    return $list[-1];
}

sub basic_request_env {
    my $self = shift;
    require Japster::Test;
    return Japster::Test->basic_request_env( @_ );
}

1;

use strict;
use warnings;
use v5.16;

package Kicky::Request;
use base 'Yasen::Request', 'Kicky::Base';

use Scalar::Util qw(blessed);
use Async::ContextSwitcher;
use Promises qw(deferred);
use Japster;

__PACKAGE__->register_exceptions(
    missing => {
        status => 404,
        title => 'Not found',
    },
);

my $japster = Japster->new( base_url => '/api/v1/' );

foreach my $model ( qw(MailTemplate) ) {
    my $class = "Kicky::Resource::$model";
    $japster->register_resource( $class );
}

sub japster { return $japster }

sub handle {
    my $self = shift;
    my ($env) = (@_);
    $self->{env} = $env;

    $self->log->debug("Checking JSON API '". $env->{PATH_INFO} ."'");

    my $japster = $self->japster;
    my $p;
    if ( eval { $p = $japster->handle( env => $env ); 1 } ) {
        return $p if $p;
    } else {
        return $japster->format_error( $@ );
    }
    $self->log->debug("Not a JSON API request");

    return $self->SUPER::handle( @_ );
}

1;

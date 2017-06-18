use strict;
use warnings;
use v5.14;

package Kicky::Payload::Mail;
use base 'Kicky::Payload';

use Kicky::Model::MailTemplate;
use Promises qw(deferred);
use Async::ContextSwitcher;

sub fetch {
    my $self = shift;
    my ($data) = (@_);
    my $res =  $self->{templates}{ $data->{template}{name} };
    return deferred->resolve->promise if $res;

    use Kicky::Model::MailTemplate;
    return Kicky::Model::MailTemplate
        ->load( dbh => $self->db->take, name => $data->{template}{name} )
        ->then(cb_w_context {
            my $tmpl = shift;
            die "No template" unless $tmpl && $tmpl->id;
            return $self->{templates}{ $tmpl->name } = $tmpl;
        });
}

sub process {
    my $self = shift;
    my $data = shift;
    my $token = shift;

    my $tmpl = $self->{templates}{ $data->{template}{name} }
        or confess("No template prefetched, wtf!?");

    my $res = $tmpl->render( lang => $data->{lang}, data => $data->{template}{payload} );
    return $res;
}

1;

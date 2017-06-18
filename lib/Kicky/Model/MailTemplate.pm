use strict;
use warnings;
use v5.16;

package Kicky::Model::MailTemplate;
use base 'Kicky::Model';

use Async::ContextSwitcher;

sub table { 'mail_templates' }

sub structure {
    return {
        id => {},
        name => {},
        title => {},
        subject => { type => 'json' },
        content => { type => 'json' },
    };
}

use Text::Handlebars;
my $hbs = Text::Handlebars->new();

sub render {
    my $self = shift;
    my %args = (
        lang => undef,
        data => {},
        @_,
    );

    my $lang = $args{lang} or confess("'lang' required");

    my %res;
    $res{subject} = $hbs->render_string(
        $self->subject->{ $lang },
        $args{data},
    );
    $res{content} = $hbs->render_string(
        $self->content->{ $lang },
        $args{data},
    );
    return \%res;
}

__PACKAGE__->generate_accessors;
1;

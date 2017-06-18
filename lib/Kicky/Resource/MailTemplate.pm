use strict;
use warnings;
use v5.16;

package Kicky::Resource::MailTemplate;
use base 'Kicky::Resource';

use Async::ContextSwitcher;
use Kicky::Model::MailTemplate;

sub attributes {
    return {
        name => {},
        title => {},
        subject => {},
        content => {},
    };
}

1;

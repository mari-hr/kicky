use strict;
use warnings;

use Test::More;
use_ok('Kicky');
use_ok('Kicky::Manager');

use_ok('Kicky::Model');
use_ok('Kicky::Model::MailTemplate');

use_ok('Kicky::Sender');
use_ok('Kicky::Sender::Mail');

use_ok('Kicky::Rabbit');
use_ok('Kicky::Resource');
use_ok('Kicky::Payload');

done_testing();

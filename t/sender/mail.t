use strict;
use warnings;
use v5.14;

use Test::More;
use Kicky::Test;
use Async::ContextSwitcher;

my $app = Kicky::Test->app;

use_ok('Kicky::Sender');
my $sender = Kicky::Sender->new( app => $app, platform => 'mail');
$sender->setup_listener;

$app->setup_db( {
    "mail-templates" => [
        {
            "name" => "test",
            "title" => "a test mail",
            "subject" => { "en" => "hello {{who}}" },
            "content" => { "en" => "hi {{who}}" },
        },
    ],
});

note "publishing a request";
{
    my $cv = AnyEvent->condvar;

    use_ok 'Kicky::Sender::Mail';
    *Kicky::Sender::Mail::run = sub {
        my $self = shift;
        print STDERR $app->dump(\@_);
    };

    $app->rabbit
    ->then(cb_w_context {
        my $r = shift;
        $r->publish(
            exchange => 'kicky_pushes_mail',
            body => $app->json->encode({
                platform => 'mail',
                lang => 'en',
                template => {
                    name => 'test',
                    payload => { who => 'world' },
                },
                recipients => [
                    'test@test.com'
                ],
            }),
        );
    })
    ->finally($cv);
    $cv->recv;

    pass "pushed a message";
}

done_testing();

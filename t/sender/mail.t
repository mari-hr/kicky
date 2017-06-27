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

$app->setup->db_import( {
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

    $cv->begin;
    use_ok 'Kicky::Sender::Mail';
    no warnings 'once', 'redefine';
    my $orig = \&Kicky::Sender::Mail::run;
    *Kicky::Sender::Mail::run = sub {
        my $rv = $orig->(@_);
        $cv->end;
        return $rv;
    };

    $cv->begin;
    my $r;
    $app->rabbit
    ->then(cb_w_context {
        $r = shift;
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
    ->finally(sub { $r = undef; $cv->end });
    $cv->recv;

    pass "pushed a message";

    my $mail = Kicky::Test->last_mail;
    is "$mail\n", <<'END', "good";
ARGS: -t,-f,bounces,-XV

Content-Type: text/html
Content-Disposition: inline
Content-Transfer-Encoding: binary
MIME-Version: 1.0
X-Mailer: MIME-tools 5.504 (Entity 5.504)
To: test@test.com
Subject: hello world

hi world
END
}

done_testing();

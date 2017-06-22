use lib '.';
use inc::Module::Install;

all_from('lib/Kicky.pm');

requires
    'Yasen' => '0.01',
    'Plum' => '0.01',
    'Japster' => '0.01',
    'AnyEvent::RabbitMQ' => 0,
    'AnyEvent' => 0,
    'Scalar::Util' => 0,
    'Text::Handlebars' => 0,
    'Promises' => 0,
    'Async::ContextSwitcher' => 0,
    'Carp' => 0,
    'DBIx::Poggy' => 0,
    'Getopt::Long' => 0,
    'MIME::Entity' => 0,
;

install_script('script/kicky-importer');
install_script('script/kicky-server.psgi');
install_script('script/kicky-setup');

WriteAll();

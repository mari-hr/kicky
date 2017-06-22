use lib '.';
use inc::Module::Install;

all_from('lib/Kicky.pm');

requires
    'Yasen' => '0.01',
    'Plum' => '0.01',
    'Japster' => '0.01',
;

install_script('script/kicky-importer');
install_script('script/kicky-server.psgi');
install_script('script/kicky-setup');

WriteAll();

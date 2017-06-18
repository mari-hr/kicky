use lib '.';
use inc::Module::Install;

all_from('lib/Kicky.pm');

requires
    'Yasen' => '0.01',
    'Plum' => '0.01',
    'Japster' => '0.01',
;

WriteAll();

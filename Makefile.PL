use strict;
use lib '.';

use inc::Module::Install;

name                ('markit');
license             ('perl');
author              ('liseen <liseen.wan@gmail.com>');
perl_version        ('5.006001');
all_from            ('lib/Markit.pm');

requires            ('VDOM' => '0.012');
requires            ('List::Util');
requires            ('Params::Util');
requires            ('Smart::Comments');
requires            ('Clone');
requires            ('JSON::XS');
requires            ('Scalar::Util');
requires            ('List::MoreUtils');
#requires            ('Class::Accessor::Fast');
build_requires      ('Test::More');
#no_index( directory => qw< t inc doc share demo > );

install_script      ('bin/markit-extract.pl');

auto_install();
WriteAll();


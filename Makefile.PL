use strict;
use inc::Module::Install;

name            ('Makefile-Parser');
all_from        ('lib/Makefile/Parser.pm');
license         ('perl');

install_script  ('script/pgmake');

requires        ('List::MoreUtils');
requires        ('Params::Util');
requires        ('Scalar::Util');
requires        ('Clone');
requires        ('Carp');

build_requires  ('Test::Simple');
build_requires  ('Test::Base');
build_requires  ('IPC::Run3');
build_requires  ('File::Temp');
build_requires  ('File::Spec');
build_requires  ('Cwd');
build_requires  ('Text::Balanced');
build_requiers  ('FindBin');
build_requires  ('Time::HiRes');

makemaker_args  (
    test => { TESTS => "t/*.t t/*/*.t t/*/*/*.t" },
);

&WriteAll;

print "--" x 30, "\n";
do 'script/checkenv';
print "--" x 30, "\n";

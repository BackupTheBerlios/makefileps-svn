use strict;
use inc::Module::Install;
my $plmake = "script/plmake";

name            ('Makefile-Parser');
version_from    ('lib/Makefile/Parser.pm');
abstract        ( 'A Simple Parser for Makefiles' );
author          ('Agent Zhang <agent2002@126.com>');
license         ('perl');

install_script  ($plmake);
#requires        ('Data::Dumper');

build_requires  ('Test::More');
build_requires  ('Test::Base');
build_requires  ('IPC::Cmd');
build_requires  ('File::Temp');
build_requires  ('File::Spec');
build_requires  ('ExtUtils::Command');
build_requires  ('Cwd');
build_requires  ('Text::Balanced');
build_requiers  ('FindBin');

makemaker_args  (
    test => { TESTS => "t/*.t t/*/*/*.t" },
);

&WriteAll;

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
build_requires  ('IPC::Run');
build_requires  ('File::Temp');
#build_requires  ('File::Compare');

makemaker_args  (
    test => { TESTS => join ' ', "t/*.t t/*/*.t", "t/*/*/*.t" }, # , "perl5/*/t/*.t" },
);

&WriteAll;

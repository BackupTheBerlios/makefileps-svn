#: redirect.t
#: test the redirection operator support of script/sh
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-10 2006-02-10

use t::Shell;

plan tests => 4 * blocks() + 5;

run_tests;

__DATA__

=== TEST 1: redirect stdout to disk file
--- cmd
echo abc >tmp
--- stdout
--- stderr
--- found:         tmp
--- post
open my $in, 'tmp';
local $/;
my $s = <$in>;
is $s, "abc\n";
close $in;
--- success:       true



=== TEST 2: ditto, another form
--- cmd
echo abc > tmp
--- stdout
--- stderr
--- found:         tmp
--- post
open my $in, 'tmp';
local $/;
my $s = <$in>;
is $s, "abc\n";
close $in;
--- success:       true



=== TEST 3: ditto, yet another
--- cmd
echo abc> tmp
--- stdout
--- stderr
--- found:         tmp
--- post
open my $in, 'tmp';
local $/;
my $s = <$in>;
is $s, "abc\n";
close $in;
--- success:       true



=== TEST 3: ditto, yet yet another
--- cmd
echo abc>tmp
--- stdout
--- stderr
--- found:         tmp
--- post
open my $in, 'tmp';
local $/;
my $s = <$in>;
is $s, "abc\n";
close $in;
--- success:       true



=== TEST 4: quoted `>'
--- cmd
echo abc '>' tmp
--- stdout
abc > tmp
--- stderr
--- found:         tmp
--- success:       true



=== TEST 5: redirect stdout to the end of a disk file
--- cmd
echo 123 > tmp; echo abc >>tmp
--- stdout
--- stderr
--- found:         tmp
--- post
open my $in, 'tmp';
local $/;
my $s = <$in>;
is $s, "123\nabc\n";
close $in;
--- success:       true

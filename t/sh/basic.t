#: basic.t
#: 2006-02-02 2006-02-02

use t::Shell;

plan tests => 3 * blocks;

run_tests;

__DATA__

=== Test 1: normal
--- cmd
echo hello, world
--- stdout
hello, world
--- stderr
--- error_code
0

=== Test 2: whitespace
--- cmd
echo hello,    world
--- stdout
hello, world
--- stderr
--- error_code
0

=== Test 3: multiple argument
--- cmd
echo a b c
--- stdout
a b c
--- stderr
--- error_code
0

=== Test 4: no argument
--- cmd
echo
--- stdout unchomp
--- stderr
--- error_code
0


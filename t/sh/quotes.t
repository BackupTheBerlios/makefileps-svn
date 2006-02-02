#: basic.t
#: 2006-02-02 2006-02-02

use t::Shell;

plan tests => 3 * blocks;

run_tests;

__DATA__

=== Test 1: basic
--- cmd
echo 'hello, world'
--- stdout
hello, world
--- stderr
--- error_code
0

=== Test 2: whitespace
--- cmd
echo 'hello,    world'
--- stdout
hello,    world
--- stderr
--- error_code trim
0


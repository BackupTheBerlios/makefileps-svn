#: quotes.t
#: test the various quotes in `sh' syntax
#: 2006-02-02 2006-02-02

use t::Shell;

plan tests => 3 * blocks() - 4;

run_tests;

__DATA__

=== Test 1: single-colon, basic
--- cmd
echo 'hello, world'
--- stdout
hello, world
--- stderr
--- error_code
0



=== Test 2: single-colon, whitespace
--- cmd
echo 'hello,    world'
--- stdout
hello,    world
--- stderr
--- error_code
0



=== Test 3: single-colon, escape '
--- cmd
echo '\''
--- stdout:



=== Test 4: single-colon, escape "
--- cmd
echo '\"'
--- stdout
\"
--- stderr
--- error_code
0



=== Test 5: single-colon, escape '\'
--- cmd
echo '\\'
--- stdout
\\
--- stderr
--- error_code
0



=== Test 6: malformed single-colon
--- cmd
echo ab''
--- stdout
ab
--- stderr
--- error_code
0



=== Test 7: ditto, another example
--- cmd
echo abcd
--- stdout
abcd
--- stderr
--- error_code
0



=== Test 8: ditto, yet another
--- cmd
echo ab'cd
--- stdout:



=== Test 9: double quotes in single quotes
--- cmd
echo '""'
--- stdout
""
--- stderr
--- error_code
0



=== Test 10: escaped single quote
--- cmd
echo \'
--- stdout
'
--- stderr
--- error_code
0

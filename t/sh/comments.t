#: comments.t
#: test comments in shell
#: 2006-02-03 2006-02-03

use t::Shell;

plan tests => 3 * blocks;

run_tests;

__DATA__

=== Test 1: basic
--- cmd
echo hello, #world
--- stdout
hello,
--- stderr
--- error_code
0



=== Test 2: `#' at the very beginning
--- cmd
#echo 'hello'
--- stdout
--- stderr
--- error_code
0



=== Test 3: `#' in the middle of word
--- cmd
echo hello#world
--- stdout
hello#world
--- stderr
--- error_code
0



=== Test 4: `#' at the end of word
--- cmd
echo hello# world!
--- stdout
hello# world!
--- stderr
--- error_code
0



=== Test 5: `#' in single quotes
--- cmd
echo 'hi, #bill!'
--- stdout
hi, #bill!
--- stderr
--- error_code
0



=== Test 6: `#' in double quotes
--- cmd
echo "hi, #jim!"
--- stdout
hi, #jim!
--- stderr
--- error_code
0



=== Test 7: escaped `#'
--- cmd
echo hello, \#world
--- stdout
hello, #world
--- stderr
--- error_code
0

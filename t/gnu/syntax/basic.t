use t::Backend::Gnu;

plan tests => 3 * blocks;

run_tests;

__DATA__

=== TEST 0: rules with no command
--- source
a: b
b: c
c:; echo  'hello!'
--- stdout
echo  'hello!'
hello!
--- stderr
--- error_code
0



=== TEST 1: command at beginning
--- source
	a: b
b: c
c:; echo  'hello!'
--- stdout
--- stderr_like
.*?commands commence before first target.*?
--- error_code
512



=== TEST 2: escaped line continuator
--- source
a: # \\
b: c
c:; echo  'hello!'
--- stdout preprocess
#MAKE#: Nothing to be done for `a'.
--- stderr
--- error_code
0



=== TEST 3: rule context
--- source
a: b

	echo "a"
b: ; echo "b"
--- stdout
echo "b"
b
echo "a"
a
--- stderr
--- success:    true



=== TEST 4: empty command
--- source
a: b
	
	echo "a"
b: ; echo "b"
--- stdout
echo "b"
b
echo "a"
a
--- stderr
--- success:    true



=== TEST 5: escaped '#'
--- source
a: \#b
	echo "a"
--- stdout
--- stderr preprocess
#MAKE#: *** No rule to make target `#b', needed by `a'.  Stop.
--- error_code
512



=== TEST 6: escaped '3'
--- source
a: \3b
	echo "a"

3b: ; echo "3b"
--- stdout
--- stderr preprocess
#MAKE#: *** No rule to make target `\3b', needed by `a'.  Stop.
--- error_code
512

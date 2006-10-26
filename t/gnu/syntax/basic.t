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



=== TEST 7: line continuation
--- source
a: \
	echo c
	echo "a"

echo: ; echo $@

c: ; echo $@

--- stdout
echo echo
echo
echo c
c
echo "a"
a
--- stderr
--- error_code
0



=== TEST 7: line continuation
--- source
a: \
	b; \
    echo $@

b: ; echo $@

--- stdout
echo b
b
\
    echo a
a
--- stderr
--- error_code
0



=== TEST 8: variables with a single character name:
--- source
a = foo
all: ; echo $a
--- stdout
echo foo
foo
--- stderr
--- error_code
0



=== TEST 9: escaped $
--- source
a = foo
all: ; echo \$a
--- stdout
echo \foo
foo
--- stderr
--- error_code
0



=== TEST 10: unescaped '#'
--- source

all: foo\\# hello
foo\\: ; echo $@

--- stdout
echo foo\
foo\
--- stderr
--- error_code
0



=== TEST 11: when no space between words and '#'
--- source

\#a: foo#hello

foo:;echo $@

--- stdout
echo foo
foo
--- stderr
--- error_code
0



=== TEST 12: comment indented with tabs
--- source
	# blah
a: ; echo hi
--- stdout
echo hi
hi
--- stderr
--- error_code
0



=== TEST 13: multi-line comment indented with tabs
--- source
	# blah \
hello!\
	# hehe
a: ; echo hi
--- stdout
echo hi
hi
--- stderr
--- error_code
0



=== TEST 14: dynamics of rules
--- source
foo = : b
a $(foo)
	echo $@
b:; echo $@
--- stdout
echo b
b
echo a
a
--- stderr
--- error_code
0



=== TEST 15: disabled suffix rules
--- source
.SUFFIXES:

all: .c.o
.c.o:
	echo "hello $<!"
--- stdout
echo "hello !"
hello !
--- stderr
--- error_code
0



=== TEST 16: static pattern rules with ";" command
--- source

foo.o bar.o: %.o: %.c ; echo blah

%.c: ; echo $@

--- stdout
echo foo.c
foo.c
echo blah
blah
--- stderr
--- error_code
0

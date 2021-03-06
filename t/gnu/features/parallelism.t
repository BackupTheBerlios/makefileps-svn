#: parallelism.t
#:
#: Description:
#:   Test parallelism (-j) option.
#: Details:
#:   This test creates a makefile with two double-colon default
#:   rules.  The first rule has a series of sleep and echo commands
#:   intended to run in series.  The second and third have just an
#:   echo statement.  When make is called in this test, it is given
#:   the -j option with a value of 4.  This tells make that it may
#:   start up to four jobs simultaneously.  In this case, since the
#:   first command is a sleep command, the output of the second
#:   and third commands will appear before the first if indeed
#:   make is running all of these commands in parallel.
#:
#: 2006-02-11 2006-02-14

use t::Backend::Gnu;

plan tests => 3 * blocks();

run_tests;

__DATA__

=== TEST 0:
--- source
all : def_1 def_2 def_3
def_1 : ; @echo ONE; sleep 3 ; echo TWO
def_2 : ; @sleep 2 ; echo THREE
def_3 : ; @sleep 1 ; echo FOUR
--- options:      -j4
--- stdout
ONE
FOUR
THREE
TWO
--- stderr
--- success:      true



=== TEST 1: Test parallelism with included files.
Here we sleep/echo while building the included files,
to test that they are being built in parallel.
--- source
all: 1 2; @echo success
-include 1.inc 2.inc
1.inc: ; @echo ONE.inc; sleep 2; echo TWO.inc; echo '1: ; @echo ONE; sleep 2; echo TWO' > $@
2.inc: ; @sleep 1; echo THREE.inc; echo '2: ; @sleep 1; echo THREE' > $@
--- options:      -j4
--- stdout
ONE.inc
THREE.inc
TWO.inc
ONE
THREE
TWO
success
--- stderr
--- success:      true



=== TEST 2: Test parallelism with included files
this time recurse first and make sure the jobserver works.
--- source preprocess

recurse: ; @$(MAKE) --no-print-directory -f #MAKEFILE# INC=yes all
all: 1 2; @echo success

INC = no
ifeq ($(INC),yes)
-include 1.inc 2.inc
endif

1.inc: ; @echo ONE.inc; sleep 2; echo TWO.inc; echo '1: ; @echo ONE; sleep 2; echo TWO' > $@
2.inc: ; @sleep 1; echo THREE.inc; echo '2: ; @sleep 1; echo THREE' > $@

--- options:      -j4
--- stdout
ONE.inc
THREE.inc
TWO.inc
ONE
THREE
TWO
success
--- stderr
--- success:      true
--- SKIP



=== TEST 3:
Grant Taylor reports a problem where tokens can be lost (not written back
to the pipe when they should be): this happened when there is a $(shell ...)
function in an exported recursive variable.  I added some code to check
for this situation and print a message if it occurred.  This test used
to trigger this code when I added it but no longer does after the fix.
--- source
export HI = $(shell $($@.CMD))
first.CMD = echo hi
second.CMD = sleep 4; echo hi

.PHONY: all first second
all: first second

first second: ; @echo $@; sleep 1; echo $@

--- options:      -j2
--- stdout
first
first
second
second
--- stderr
--- success:      true



=== TEST 4:
Michael Matz <matz@suse.de> reported a bug where if make is running in
parallel without -k and two jobs die in a row, but not too close to each
other, then make will quit without waiting for the rest of the jobs to die.
--- source
.PHONY: all fail.1 fail.2 fail.3 ok
all: fail.1 ok fail.2 fail.3

fail.1 fail.2 fail.3:
	@sleep $(patsubst fail.%,%,$@)
	@echo Fail
	@exit 1

ok:
	@sleep 4
	@echo Ok done
--- options:      -rR -j5
--- stdout
Fail
Fail
Fail
Ok done
--- stderr preprocess
#MAKE#: *** [fail.1] Error 1
#MAKE#: *** Waiting for unfinished jobs....
#MAKE#: *** [fail.2] Error 1
#MAKE#: *** [fail.3] Error 1
--- success:      false

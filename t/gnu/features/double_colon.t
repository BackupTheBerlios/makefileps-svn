#: double_colon.t
#:
#: Description:
#:   Test handling of double-colon rules.
#: Details:
#:   We test these features:
#:     - Multiple commands for the same (double-colon) target
#:     - Different prerequisites for targets: only out-of-date
#:       ones are rebuilt.
#:     - Double-colon targets that aren't the goal target.
#:   Then we do the same thing for parallel builds: double-colon
#:   targets should always be built serially.
#:
#: 2006-01-30 2006-02-01

use t::Parser::Gnu;

plan tests => 3 * blocks;

filters {
    source     => [qw< quote eval >],
};

our $source = <<'_EOC_';

all: baz

foo:: f1.h ; @echo foo FIRST
foo:: f2.h ; @echo foo SECOND

bar:: ; @echo aaa; sleep 1; echo aaa done
bar:: ; @echo bbb

baz:: ; @echo aaa
baz:: ; @echo bbb

biz:: ; @echo aaa
biz:: two ; @echo bbb

two: ; @echo two

f1.h f2.h: ; @echo $@

d :: ; @echo ok
d :: d ; @echo oops

_EOC_

run { run_test_make $_[0]; }

__DATA__

=== TEST 0
TEST 0: A simple double-colon rule that isn't the goal target.
--- source:            $::source
--- goals:             all
--- stdout
aaa
bbb
--- stderr
--- error_code
0



=== TEST 1
TEST 1: As above, in parallel
--- source:            $::source
--- options:           -j10
--- goals:             all
--- stdout
aaa
bbb
--- stderr
--- error_code
0



=== TEST 2
TEST 2: A simple double-colon rule that is the goal target
--- source:            $::source
--- goals:             bar
--- stdout
aaa
aaa done
bbb
--- stderr
--- error_code
0



=== TEST 3
TEST 3: As above, in parallel
--- source:            $::source
--- options:           -j10
--- goals:             bar
--- stdout
aaa
aaa done
bbb
--- stderr
--- error_code
0



=== TEST 4
TEST 4: Each double-colon rule is supposed to be run individually
--- source:            $::source
--- utouch
-5 f2.h
--- touch
foo
--- goals: foo
--- stdout
f1.h
foo FIRST
--- stderr
--- error_code
0



=== TEST 5
TEST 5: Again, in parallel.
--- source:            $::source
--- options:           -j10
--- utouch:            -5 f2.h
--- touch:             foo
--- goals:             foo
--- stdout
f1.h
foo FIRST
--- stderr
--- error_code
0



=== TEST 6
TEST 6: Each double-colon rule is supposed to be run individually
--- source:            $::source
--- utouch:            -5 f1.h
--- touch:             foo
--- goals:             foo
--- stdout
f2.h
foo SECOND
--- stderr
--- error_code
0



=== TEST 7
TEST 7: Again, in parallel.
--- source:            $::source
--- options:           -j10
--- utouch:            -5 f1.h
--- touch:             foo
--- goals:             foo
--- stdout
f2.h
foo SECOND
--- stderr
--- error_code
0



=== TEST 8
TEST 8: Test circular dependency check; PR/1671
--- source:            $::source
--- goals:             d
--- stdout
ok
oops
--- stderr quote eval
$::MAKE: Circular d <- d dependency dropped.
--- error_code
0



=== Commented TEST 8
TEST 8: I don't grok why this is different than the above, but it is...
Hmm... further testing indicates this might be timing-dependent?
--- source:            $::source
--- goals:             biz
--- options:           -j10
--- stdout
aaa
two
bbb
--- stderr
--- error_code
0

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
#: 2006-01-30 2006-01-31

use t::Parser;

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

=== dcolon rule, not a goal
A simple double-colon rule that isn't the goal target
--- source:            $::source
--- goals:             all
--- stdout
aaa
bbb
--- stderr
--- error_code
0



=== dcolon rule, not a goal, in parallel
As above, in parallel.
--- source:            $::source
--- options:           -j10
--- goals:             all
--- stdout
aaa
bbb
--- stderr
--- error_code
0



=== dcolon rule, is a goal
A simple double-colon rule that is the goal target
--- source:            $::source
--- goals:             bar
--- stdout
aaa
aaa done
bbb
--- stderr
--- error_code
0



=== dcolon rule, is a goal, parallel
As above, in parallel
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



=== dcolon rules run individually
Each double-colon rule is supposed to be run individually
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



=== dcolon rules run individually, in parallel
Again, in parallel.
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



=== dcolon rules run individually
Each double-colon rule is supposed to be run individually
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



=== dcolon rules run individually, in parallel
Again, in parallel.
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



=== circular dependency
Test circular dependency check; PR/1671
--- source:            $::source
--- goals:             d
--- stdout
ok
oops
--- stderr quote eval
$t::Parser::MAKE: Circular d <- d dependency dropped.
--- error_code
0



=== strange one
I don't grok why this is different than the above, but it is...
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

#: export.t
#:
#: Description:
#:   Check GNU make export/unexport commands.
#: Details:
#:
#: 2006-01-31 2006-01-31

# t::Parser cleans out our environment for us during startup 
# so we don't have to worry about that here.

use t::Parser;

plan tests => 3 * blocks;

util_path '../..';

filters {
    source     => [qw< quote eval >],
};

our $makefile = <<'_EOC_';

FOO = foo
BAR = bar
BOZ = boz

export BAZ = baz
export BOZ

BITZ = bitz
BOTZ = botz

export BITZ BOTZ
unexport BOTZ

ifdef EXPORT_ALL
export
endif

ifdef UNEXPORT_ALL
unexport
endif

ifdef EXPORT_ALL_PSEUDO
.EXPORT_ALL_VARIABLES:
endif

all:
	@echo FOO=$(FOO) BAR=$(BAR) BAZ=$(BAZ) BOZ=$(BOZ) BITZ=$(BITZ) BOTZ=$(BOTZ)
	@$(ECHO_ENV) FOO BAR BAZ BOZ BITZ BOTZ

_EOC_

run { run_test_make $_[0]; }

__DATA__

=== basics
--- source:         $::makefile
--- stdout
FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO= BAR= BAZ=baz BOZ=boz BITZ=bitz BOTZ=
--- stderr
--- error_code
0

=== vars inherited from others exported
make sure vars inherited from the parent are exported
--- pre:            $ENV{FOO} = 1;
--- post:           delete $ENV{FOO};
--- source:         $::makefile
--- stdout
FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO=foo BAR= BAZ=baz BOZ=boz BITZ=bitz BOTZ=
--- stderr
--- error_code
0

# TEST 2: global export.  Explicit unexport takes precedence.

&run_make_with_options($makefile,"EXPORT_ALL=1",&get_logfile,0);

$answer = "FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=\n";

&compare_output($answer,&get_logfile(1));

# TEST 3: global unexport.  Explicit export takes precedence.

&run_make_with_options($makefile,"UNEXPORT_ALL=1",&get_logfile,0);

$answer = "FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO= BAR= BAZ=baz BOZ=boz BITZ=bitz BOTZ=\n";

&compare_output($answer,&get_logfile(1));

# TEST 4: both: in the above makefile the unexport comes last so that rules.

&run_make_with_options($makefile,"EXPORT_ALL=1 UNEXPORT_ALL=1",&get_logfile,0);

$answer = "FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO= BAR= BAZ=baz BOZ=boz BITZ=bitz BOTZ=\n";

&compare_output($answer,&get_logfile(1));

# TEST 5: test the pseudo target.

&run_make_with_options($makefile,"EXPORT_ALL_PSEUDO=1",&get_logfile,0);

$answer = "FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=botz
FOO=foo BAR=bar BAZ=baz BOZ=boz BITZ=bitz BOTZ=\n";

&compare_output($answer,&get_logfile(1));


# TEST 6: Test the expansion of variables inside export

$makefile2 = &get_tmpfile;

open(MAKEFILE, "> $makefile2");

print MAKEFILE <<'EOF';

foo = f-ok
bar = b-ok

FOO = foo
F = f

BAR = bar
B = b

export $(FOO)
export $(B)ar

all:
	@echo foo=$(foo) bar=$(bar)
	@echo foo=$$foo bar=$$bar

EOF

close(MAKEFILE);

&run_make_with_options($makefile2,"",&get_logfile,0);
$answer = "foo=f-ok bar=b-ok\nfoo=f-ok bar=b-ok\n";
&compare_output($answer,&get_logfile(1));


# TEST 7: Test the expansion of variables inside unexport

$makefile3 = &get_tmpfile;

open(MAKEFILE, "> $makefile3");

print MAKEFILE <<'EOF';

foo = f-ok
bar = b-ok

FOO = foo
F = f

BAR = bar
B = b

export foo bar

unexport $(FOO)
unexport $(B)ar

all:
	@echo foo=$(foo) bar=$(bar)
	@echo foo=$$foo bar=$$bar

EOF

close(MAKEFILE);

&run_make_with_options($makefile3,"",&get_logfile,0);
$answer = "foo=f-ok bar=b-ok\nfoo= bar=\n";
&compare_output($answer,&get_logfile(1));


# TEST 7: Test exporting multiple variables on the same line

$makefile4 = &get_tmpfile;

open(MAKEFILE, "> $makefile4");

print MAKEFILE <<'EOF';

A = a
B = b
C = c
D = d
E = e
F = f
G = g
H = h
I = i
J = j

SOME = A B C

export F G H I J

export D E $(SOME)

all: ; @echo A=$$A B=$$B C=$$C D=$$D E=$$E F=$$F G=$$G H=$$H I=$$I J=$$J
EOF

close(MAKEFILE);

&run_make_with_options($makefile4,"",&get_logfile,0);
$answer = "A=a B=b C=c D=d E=e F=f G=g H=h I=i J=j\n";
&compare_output($answer,&get_logfile(1));


# TEST 8: Test unexporting multiple variables on the same line

$makefile5 = &get_tmpfile;

open(MAKEFILE, "> $makefile5");

print MAKEFILE <<'EOF';

A = a
B = b
C = c
D = d
E = e
F = f
G = g
H = h
I = i
J = j

SOME = A B C

unexport F G H I J

unexport D E $(SOME)

all: ; @echo A=$$A B=$$B C=$$C D=$$D E=$$E F=$$F G=$$G H=$$H I=$$I J=$$J
EOF

close(MAKEFILE);

@ENV{qw(A B C D E F G H I J)} = qw(1 2 3 4 5 6 7 8 9 10);

&run_make_with_options($makefile5,"",&get_logfile,0);
$answer = "A= B= C= D= E= F= G= H= I= J=\n";
&compare_output($answer,&get_logfile(1));

delete @ENV{qw(A B C D E F G H I J)};


# This tells the test driver that the perl test script executed properly.
1;

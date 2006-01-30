#: conditionals.t
#:
#: Description:
#:   Check GNU make conditionals.
#: Details:
#:   Attempt various different flavors of GNU make conditionals.
#:
#: 2006-01-29 2006-01-30

use t::Parser;

plan tests => 3 * blocks;

run { run_test_make $_[0]; }

__DATA__

=== Check GNU make conditionals
Attempt various different flavors of GNU make conditionals.
--- source

objects = foo.obj
arg1 = first
arg2 = second
arg3 = third
arg4 = cc
arg5 = second

all:
ifeq ($(arg1),$(arg2))
	@echo arg1 equals arg2
else
	@echo arg1 NOT equal arg2
endif

ifeq '$(arg2)' "$(arg5)"
	@echo arg2 equals arg5
else
	@echo arg2 NOT equal arg5
endif

ifneq '$(arg3)' '$(arg4)'
	@echo arg3 NOT equal arg4
else
	@echo arg3 equal arg4
endif

ifndef undefined
	@echo variable is undefined
else
	@echo variable undefined is defined
endif
ifdef arg4
	@echo arg4 is defined
else
	@echo arg4 is NOT defined
endif

--- stdout
arg1 NOT equal arg2
arg2 equals arg5
arg3 NOT equal arg4
variable is undefined
arg4 is defined
--- stderr
--- error_code
0



=== variable in infdef
Test expansion of variables inside ifdef
--- source

foo = 1

FOO = foo
F = f

DEF = no
DEF2 = no

ifdef $(FOO)
DEF = yes
endif

ifdef $(F)oo
DEF2 = yes
endif

all:; @echo DEF=$(DEF) DEF2=$(DEF2)

--- stdout
DEF=yes DEF2=yes
--- stderr
--- error_code
0

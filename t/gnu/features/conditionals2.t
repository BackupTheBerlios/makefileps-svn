#: conditionals2.t
#: 2006-02-10 2006-02-10

use t::Backend::Gnu;

plan tests => 3 * blocks;

run_tests;

__DATA__

=== TEST 1: what if we escape the single quote in `ifdef' by a backslash?
--- filename:        foo
--- source
arg3 = third
arg4 = cc

all:
ifneq \'$(arg3)\' \'$(arg4)\'
	@echo arg3 NOT equal arg4
else
	@echo arg3 equal arg4
endif

--- stdout
--- stderr
foo:5: *** invalid syntax in conditional.  Stop.
--- success:        false



=== TEST 1: what if we escape the single quote in `else ifdef' by a backslash?
--- filename:        baz.mk
--- source
arg1 = first
arg2 = second
arg5 = fifth

result =

ifeq ($(arg1),$(arg2))
  result += arg1 equals arg2
else ifeq \'$(arg2)\' "$(arg5)"
  result += arg2 equals arg5
else
  result += success
endif

all: ; @echo $(result)

--- stdout
--- stderr_like
baz\.mk:9: Extraneous text after `else' directive
(.|\n)*
--- success:        false



=== TEST 2: what if we omit the parentheses for `ifeq'?
--- filename:       Makefile
--- source
arg1 = first
arg2 = second

all:
ifeq $(arg1), $(arg2)
	@echo arg1 equals arg2
else
	@echo arg1 NOT equal arg2
endif

--- stdout
--- stderr
Makefile:5: *** invalid syntax in conditional.  Stop.
--- success:        false



=== TEST 3: what if we omit the quotes completely?
--- filename:       bar
--- source
arg3 = third
arg4 = cc

all:
ifneq '$(arg3)' $(arg4)
	@echo arg3 NOT equal arg4
else
	@echo arg3 equal to arg4
endif

--- stdout
--- stderr
bar:5: *** invalid syntax in conditional.  Stop.
--- success:        false



=== TEST 4: Does it matter if we add redundant quotes to the `ifndef' directive?
--- source
undefined = blah blah blah
all:
ifndef 'undefined'
	@echo variable $('undefined') is undefined
else
	@echo variable undefined is defined
endif
--- stdout
variable is undefined
--- stderr
--- success:        true



=== TEST 5: Is the whitespace after the `ifeq' directive critical?
--- filename:       foo
--- source
arg1 = first
arg2 = second

all:
ifeq($(arg1),$(arg2))
	@echo arg1 equals arg2
else
	@echo arg1 NOT equal arg2
endif

--- stdout
--- stderr
foo:5: *** missing separator.  Stop.
--- success:        false



=== TEST 6: Is the whitespace between the two quoted arguments critical?
--- filename:       bar
--- source
arg1 = first
arg2 = second

all:
ifeq '$(arg1)''$(arg2)'
	@echo arg1 equals arg2
else
	@echo arg1 NOT equal arg5
endif
--- stdout
arg1 NOT equal arg5
--- stderr
--- success:        true

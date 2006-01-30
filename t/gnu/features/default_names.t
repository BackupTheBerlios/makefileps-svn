#: default_names.t
#: Check default makefile names
#:   This script tests to make sure that Make looks for
#:   default makefiles in the correct order (GNUmakefile, makefile, Makefile)
#: 2006-01-29 2006-01-30

use t::Parser;

our $IS_UNIX;

BEGIN {
    if ($^O =~ /Solaris|UNIX|Linux|[a-z]+bsd|Darwin/i) {
        $IS_UNIX = 1;
    }
}

plan tests => 3 * blocks;

run { run_test_make $_[0]; }

__DATA__

=== `GNUmakefile', `makefile' and `Makefile'
When `GNUmakefile', `makefile', and `Makefile' appeare at the same time,
`GNUmakefile' should be used.
--- pre
# Create a makefile called "GNUmakefile"
create_file("GNUmakefile", "FIRST: ; \@echo It chose GNUmakefile\n");

# Create another makefile called "makefile"
create_file("makefile", "SECOND: ; \@echo It chose makefile\n");

# DOS/WIN32 platforms preserve case, but Makefile is the same file as makefile.
# Just test what we can here (avoid Makefile versus makefile test).
#
if ($::IS_UNIX) {
    # Create another makefile called "Makefile"
    create_file("Makefile", "THIRD: ; \@echo It chose Makefile\n");
}

--- stdout
It chose GNUmakefile

--- stderr
--- error_code
0

=== Only `makefile' and `Makefile'
When only `makefile' and `Makefile' are present in the current directory,
`makefile' is favored.
--- pre
create_file("makefile", "SECOND: ; \@echo It chose makefile\n");

if ($::IS_UNIX) {
    create_file("Makefile", "THIRD: ; \@echo It chose Makefile\n");
}

--- stdout
It chose makefile
--- stderr
--- error_code
0

=== Single `Makefile'
--- pre
create_file("Makefile", "THIRD: ; \@echo It chose Makefile\n");
--- stdout
It chose Makefile
--- stderr
--- error_code
0

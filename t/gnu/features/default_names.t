#: default_names.t
#: Check default makefile names
#:   This script tests to make sure that Make looks for
#:   default makefiles in the correct order (GNUmakefile, makefile, Makefile)
#: 2006-01-29 2006-01-30

use t::Parser;
use File::Temp;

our $CASE_OK;

BEGIN {
    # Haven't hack out a better way to figure out whether the current platform
    #   distinguishes character case in file name. :(
    my $me = $0;
    #warn "ME: $me";
    $me =~ s/[a-z]+/uc($&)/ge or
    $me =~ s/[A-Z]+/lc($&)/ge;
    $CASE_OK = not -f $me;
    #warn "CASE OK: $CASE_OK";
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
if ($::CASE_OK) {
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

if ($::CASE_OK) {
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

#: comments.t
#: 2006-01-29 2006-01-29

use t::Parser tests => 3;

run {
    my $block = shift;
    run_exe $block;
};

__DATA__

=== multi-line comment
The following test creates a makefile to test comments
and comment continuation to the next line using a
backslash within makefiles.
--- makefile
# Test comment vs semicolon parsing and line continuation
target: # this ; is just a comment \
	@echo This is within a comment. 
	@echo There should be no errors for this makefile.
--- stdout
There should be no errors for this makefile.
--- stderr
--- error_code
0

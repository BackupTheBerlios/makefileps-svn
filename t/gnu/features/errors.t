#: errors.t
#:
#: Description:
#:   The following tests the -i option and the '-' in front of
#:   commands to test that make ignores errors in these commands
#:   and continues processing
#: Details:
#:   This test runs two makes.  The first runs on a target with a
#:   command that has a '-' in front of it (and a command that is
#:   intended to fail) and then a delete command after that is
#:   intended to succeed.  If make ignores the failure of the first
#:   command as it is supposed to, then the second command should
#:   delete a file and this is what we check for.  The second make
#:   that is run in this test is identical except that the make
#:   command is given with the -i option instead of the '-' in
#:   front of the command.  They should run the same.
#:
#: 2006-01-30 2006-01-30

use t::Parser;
use File::Spec;

plan tests => 4 * blocks;

no_diff();

(my $rm = $0) =~ s[errors\.t$][../../rm_file.pl]i;
$rm = File::Spec->rel2abs( $rm ) ;
our $delete_command    = "$^X $rm";

our $cleanit_error     = "unable to remove `cleanit'";
our $delete_error_code = 1;

our $source = <<_EOC_;
clean:
\t-$delete_command cleanit
\t$delete_command foo
clean2: 
\t$delete_command cleanit
\t$delete_command foo
_EOC_

run { run_test_make $_[0]; }

__DATA__

=== ignore cmd error with `-'
If make acted as planned, it should ignore the error from the first
command in the target and execute the second which deletes the file "foo".
This file, therefore, should not exist if the test PASSES.
--- source quote eval:    $::source
--- touch:                foo
--- stdout quote eval
$::delete_command cleanit
$::delete_command foo
--- stderr quote eval
$::cleanit_error
$t::Parser::MAKE: [clean] Error $::delete_error_code (ignored)
--- error_code
0
--- not_found:            foo


=== ignore cmd error with `-i' option open
--- options:              -i
--- goals:                clean2
--- source quote eval:    $::source
--- touch:                foo
--- stdout quote eval
$::delete_command cleanit
$::delete_command foo
--- stderr quote eval
$::cleanit_error
$t::Parser::MAKE: [clean2] Error $::delete_error_code (ignored)
--- error_code
0
--- not_found:             foo
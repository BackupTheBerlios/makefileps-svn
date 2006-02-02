#: t/Backend/Gnu.pm
#: 2006-02-01 2006-02-02

package t::Backend::Gnu;

use t::Backend::Base -Base;
use FindBin;

my $UTIL_PATH = File::Spec->catdir($FindBin::Bin, '../../../script');
my $sh_vm  = $PERL . ' ' . File::Spec->catfile($UTIL_PATH, 'sh');

set_make('GNU_MAKE_PATH', 'make');
set_shell('GNU_SHELL_PATH', $sh_vm);

# to ease debugging (the output is normally small)
no_diff();

1;

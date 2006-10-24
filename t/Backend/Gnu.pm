#: t/Backend/Gnu.pm
#: Makefile::Parser::Gnu backend tester framework
#: subclassed t::Backend::Base
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-01 2006-03-08

package t::Backend::Gnu;

use t::Backend::Base -Base;
use FindBin;
#use Data::Dumper::Simple;

my $UTIL_PATH = File::Spec->catdir($FindBin::Bin, '../../../script');
my $MAIN_PATH = File::Spec->catdir($FindBin::Bin, '../../../script');
my $sh_vm  = $PERL . ' ' . File::Spec->catfile($UTIL_PATH, 'sh');
my $pgmake = $PERL . ' ' . File::Spec->catfile($MAIN_PATH, 'pgmake');

$ENV{MAKELEVEL} = 0;

set_make('GNU_MAKE_PATH', $pgmake);
set_shell('GNU_SHELL_PATH', $sh_vm);
set_filters(
    stdout => sub {
        my ($s) = @_;
        return $s unless $s;
        return $s;
    },
    stderr => sub {
        my ($s) = @_;
        return $s unless $s;
        $s =~ s/^$MAKE(?:\[\d+\])?:\s+Warning:\s+File `\S+' has modification time \S+ s in the future\n//gsmi;
        $s =~ s/^$MAKE(?:\[\d+\])?:\s+warning:  Clock skew detected\.  Your build may be incomplete\.\n//gsmi;
        return $s;
    },
);

# to ease debugging (the output is normally small)
no_diff();

1;

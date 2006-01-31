#: rm_f.pl
#: 2006-01-30 2006-01-31

# WARNING: don't modify this script, since the test suit depends on it. -- agent

use strict;
use warnings;

if (not unlink $ARGV[0]) {
    warn "unable to remove `$ARGV[0]'\n";
    exit (1);
}
exit(0);

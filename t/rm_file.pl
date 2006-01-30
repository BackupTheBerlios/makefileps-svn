use strict;
use warnings;

if (not unlink $ARGV[0]) {
    warn "unable to remove `$ARGV[0]'\n";
    exit (1);
}
exit(0);

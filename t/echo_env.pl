#: echo_env.pl
#: 2006-01-31 2006-01-31

# WARNING: don't edit this file, since the test suit depends on it. -- agent

use strict;

# usage: echo_env BAR FOO BITS ...

my @vars = @ARGV;
my @vals = map { $ENV{$_} } @vars;
my @items;
foreach (0..$#vars) {
    push @items, "$vars[$_]=$vals[$_]";
}
print join(' ', @items), "\n";

0;

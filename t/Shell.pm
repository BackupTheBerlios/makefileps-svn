#: t/Shell.pm
#: Testing framework for t/sh/*.t

package t::Shell;

use Test::Base -Base;
use t::Util;
use FindBin;
use Data::Dumper::Simple;

our @EXPORT = qw( run_tests run_test );

our $SHELL;

BEGIN {
    $SHELL = $ENV{TEST_SHELL_PATH} || "$^X $FindBin::Bin/../../script/sh";
}

sub run_test ($) {
    my $block = shift;
    #$SHELL = 'bash';
    #warn Dumper($SHELL);
    my @res = split_arg($SHELL);
    #warn Dumper(@res);
    my ($error_code, $stdout, $stderr) = run_shell( [@res, '-c', $block->cmd] );
    my ($stdout2, $stderr2, $error_code2) =
        ($block->stdout, $block->stderr, $block->error_code);

    my $name = $block->name;
    is ($stdout, $stdout2, "stdout - $name") if defined $stdout2;
    is ($stderr, $stderr2, "stderr - $name") if defined $stderr2;
    is ($error_code, $error_code2, "error_code - $name") if defined $error_code2;
}

sub run_tests () {
    for my $block (blocks) {
        run_test($block);
    }
}

filters {
    cmd            => [qw< chomp >],
    error_code     => [qw< eval >],
};

1;

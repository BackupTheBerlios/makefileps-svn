#: t/Shell.pm
#: Testing framework for t/sh/*.t

package t::Shell;

use Test::Base -Base;
use t::Util;
use FindBin;
#use Data::Dumper::Simple;

our @EXPORT = qw( run_tests run_test );

our $SHELL;

BEGIN {
    $SHELL = $ENV{TEST_SHELL_PATH} || "$^X $FindBin::Bin/../../script/sh";
}

sub run_test ($) {
    my $block = shift;
    #warn Dumper($block->cmd);
    process_pre($block);
    my ($error_code, $stdout, $stderr) = 
        run_shell( [ split_arg($SHELL), '-c', $block->cmd ] );
    #warn Dumper($stdout);
    process_post($block);
    my $stdout2     = $block->stdout;
    my $stderr2     = $block->stderr;
    my $error_code2 = $block->error_code;

    my $name = $block->name;
    SKIP: {
        skip 'Skip the test uncovers IPC::Cmd buffer bug on Win32', 1
            if $^O =~ /MSWin/i and $stdout2 eq qq{\\"\n};
        is ($stdout, $stdout2, "stdout - $name") if defined $stdout2;
    };
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

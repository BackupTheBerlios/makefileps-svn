#: t/Shell.pm
#: Testing framework for t/sh/*.t
#: 2006-02-02 2006-02-03

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

    my $cmd = [ split_arg($SHELL), '-c', $block->cmd() ];
    if ($^O eq 'MSWin32' and $block->stdout eq qq{\\"\n}) {
        workaround($block, $cmd);
    } else {
        test_shell_command($block, $cmd);
    }

    process_post($block);
}

sub workaround (@) {
    my ($block, $cmd) = @_;
    my ($error_code, $stdout, $stderr) = 
        run_shell( $cmd );
    #warn Dumper($stdout);
    my $stdout2     = $block->stdout;
    my $stderr2     = $block->stderr;
    my $error_code2 = $block->error_code;

    my $name = $block->name;
    SKIP: {
        skip 'Skip the test uncovers IPC::Cmd buffer bug on Win32', 3
            if 1;
        is ($stdout, $stdout2, "stdout - $name");
        is ($stderr, $stderr2, "stderr - $name");
        is ($error_code, $error_code2, "error_code - $name");
    }
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

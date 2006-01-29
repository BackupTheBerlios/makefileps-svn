package t::Parser;
use Test::Base -Base;

use File::Temp;
use IPC::Run;
use IPC::Cmd;

#filters {
#    url         => [qw< prepend=http:// get >],
#    contains    => [qw< split regexp=xs >],
#};

our $MAKE;
BEGIN {
    $MAKE = $ENV{GNU_MAKE} || 'make';
}

our $TIME_OUT = 10;

our @EXPORT = qw( run_exe );

sub run_exe($) {
    my $block = shift;
    my $name = $block->name;
    my $makefile = $block->makefile;
    my $stdout2   = $block->stdout;
    my $stderr2   = $block->stderr;
    my $output2   = $block->output;
    my $errcode2 = $block->error_code;
    if ($errcode2 and $errcode2 =~ /\d+/s) {
        $errcode2 = $&;
    }
    return if not $stdout2 and not $stderr2;
    my $tmp = new File::Temp(
        TEMPLATE => 'Makefile_XXXXX',
        DIR => '.',
    );
    my $fname = $tmp->filename;
    print $tmp $makefile;
    close $tmp;
    my $cmd = "$MAKE -f $fname";
    my ($out, $err);

    my( $success, $errcode, $routput, $rstdout, $rstderr ) =
            IPC::Cmd::run( command => $cmd, verbose => 0 );
    local $" = '';
    my ($output, $stdout, $stderr) =
        ("@$routput", "@$rstdout", "@$rstderr",);
    #warn "\nfull: $output\nstderr: $stderr\nstdout: $stdout\n";
    is $errcode, $errcode2, "Error Code - $name" if defined $errcode2;
    is $output, $output2, "Full Output Buffer - $name" if defined $output2;
    is $stdout, $stdout2, "stdout - $name" if defined $stdout2;
    is $stderr, $stderr2, "stderr - $name" if defined $stderr2;
}

package t::Parser::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

1;

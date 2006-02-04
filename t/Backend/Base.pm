#: t/Backend/Base.pm
#: Tester based on Test::Base
#: 2006-01-29 2006-02-04

package t::Backend::Base;

use Test::Base -Base;
use t::Backend::Util;
use File::Temp qw( tempdir tempfile );
use Cwd ();
use File::Spec ();
use FindBin;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    run_test run_tests create_file
    $MAKE $PERL $SHELL
);

our @EXPORT_BASE = qw(set_make set_shell);

our ($SHELL, $PERL, $MAKE, $MAKE_PATH);
our @MakeExe;

sub set_make ($$) {
    my ($env_name, $default) = @_;
    $MAKE_PATH = $ENV{$env_name} || $default;
    if ($MAKE_PATH =~ /\w*make\w*/i) {
        $MAKE = $&;
    } else {
        $MAKE = 'make';
    }
}

sub set_shell ($$) {
    my ($env_name, $default) = @_;
    $SHELL = $ENV{$env_name} || $default;
}

BEGIN {
    if ($^O =~ / /) {
        $PERL = 'perl';
    } else {
        $PERL = $^X;
    }
    #warn $PERL;

    # Get a clean environment
    clean_env();
}

sub run_test ($) {
    my $block = shift;

    my $tempdir = tempdir( 'backend_XXXXXX', CLEANUP => 1 );
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    my $filename = $block->filename;
    my $source   = $block->source;
    preprocess($source);
    $filename = create_file($filename, $source) if $source;

    process_pre($block);
    process_touch($block);
    process_utouch($block);

    run_make($block, $filename);

    process_post($block);
    process_found($block);
    process_not_found($block);

    clean_temp();
    chdir $saved_cwd;
    #warn "\nstderr: $stderr\nstdout: $stdout\n";
}

sub run_tests () {
    for my $block (blocks()) {
        run_test($block);
    }
}

sub preprocess ($) {
    return if not defined $_[0];
    subs_var($_[0], 'PERL',     $PERL    );
}

sub subs_var ($$$) {
    $_[0] =~ s/\$ [ { \( ] $_[1] [ \) } ]/$_[2]/gsx;
}

sub create_file ($$) {
    my ($filename, $content) = @_;
    my $fh;
    if (not $filename) {
        ($fh, $filename) = 
            tempfile( "create_file_XXXXX", DIR => '.', UNLINK => 1 );
    } else {
        open $fh, "> $filename" or
            confess("can't open $filename for writing: $!");
        mark_temp($filename);
    }
    $content .= "\n\nSHELL=$SHELL" if $SHELL;
    print $fh $content;
    close $fh;
    return $filename;
}

sub process_touch ($) {
    my $block = shift;
    my $buf = $block->touch;
    return if not $buf;
    touch(split /\s+/, $buf);
}

sub process_utouch ($) {
    my $block = shift;
    my $buf = $block->utouch;
    return if not $buf;
    utouch(split /\s+/, $buf);
}

# returns ($errcode, $stdout, $stderr) or $errcode
sub run_make($$) {
    my ($block, $filename) = @_;
    my $options  = $block->options || '';
    my $goals    = $block->goals || '';

    @MakeExe = split_arg($MAKE_PATH) if not @MakeExe;
    my @args = @MakeExe;
    #warn Dumper($filename);
    if ($filename) {
        push @args, '-f', $filename;
    }
    my $cmd = [ @args, process_args("$options $goals") ];
    #warn Dumper($cmd);

    # fixed the problem due to recursive invoking of `make' via filters:
    test_shell_command(
        $block, $cmd,
        stdout => sub {
            return unless $_[0];
            $_[0] =~ s/^ $MAKE \[ \d+ \] :
                \s* (?: Leaving | Entering ) \s*
                directory [^\n]+ \n//gsmix;
            $_[0] =~ s/^$MAKE\[\d+\]: /$MAKE: /gsm;
        },
        stderr => sub {
            return unless $_[0];
            $_[0] =~ s/^$MAKE\[\d+\]: /$MAKE: /gsm;
        },
    );
}

package t::Backend::Base::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

1;

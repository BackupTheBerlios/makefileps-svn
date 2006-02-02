#: t/Backend/Base.pm
#: Tester based on Test::Base
#: 2006-01-29 2006-02-01

package t::Backend::Base;

use Test::Base -Base;
use t::Backend::Util;
use File::Temp qw( tempdir tempfile );
use Cwd ();
use File::Spec ();
use FindBin;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    run_test_make create_file
    $MAKE $PERL $SHELL
);

our @EXPORT_BASE = qw(set_make set_shell);

our ($SHELL, $PERL, $MAKE, $MAKE_PATH);

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

sub run_test_make ($) {
    my $block = shift;

    my $tempdir = tempdir();
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    my $filename = $block->filename;
    my $source   = $block->source;
    preprocess($source);
    $filename = create_file($filename, $source) if $source;

    process_pre($block);
    process_touch($block);
    process_utouch($block);

    my ($errcode, $stdout, $stderr) =
        run_make($block, $filename);

    process_post($block);
    process_found($block);
    process_not_found($block);

    clean_env();
    chdir $saved_cwd;
    #warn "\nstderr: $stderr\nstdout: $stdout\n";

    process_output($block, $errcode, $stdout, $stderr);
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
        ($fh, $filename) = tempfile( "create_file_XXXXX", DIR => '.', UNLINK => 1 );
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

    #warn Dumper($filename);
    if ($filename) {
        $options = "-f '$filename' $options";
    }
    my $cmd = [ split_arg($MAKE_PATH), split_arg($options), split_arg($goals) ];
    #warn Dumper($cmd);
    my @res = run_shell($cmd);
    return @res;
}

sub process_output ($$$$) {
    my ($block, $errcode, $stdout, $stderr) = @_;

    my $stdout2  = $block->stdout;
    my $stderr2  = $block->stderr;
    my $errcode2 = $block->error_code;

    if ($errcode2 and $errcode2 =~ /\d+/s) {
        $errcode2 = $&;
    }

    my $name = $block->name;

    # fixed the problem due to recursive invoking of `make':
    $stdout =~ s/^$MAKE\[\d+\]: (?:Leaving|Entering) directory [^\n]+\n//gsm;
    $stdout =~ s/^$MAKE\[\d+\]: /$MAKE: /gsm;
    $stderr =~ s/^$MAKE\[\d+\]: /$MAKE: /gsm;

    is $errcode, $errcode2, "Error Code - $name" if defined $errcode2;
    is $stdout, $stdout2, "stdout - $name" if defined $stdout2;
    is $stderr, $stderr2, "stderr - $name" if defined $stderr2;
}

package t::Backend::Base::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

1;

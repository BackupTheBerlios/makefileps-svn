#: t/Parser.pm
#: Tester based on Test::Base
#: 2006-01-29 2006-01-30

package t::Parser;
use Test::Base -Base;

our @EXPORT = qw( run_test_make );

use File::Temp qw[ tempdir tempfile ];
use Cwd ();
use IPC::Run;
use IPC::Cmd;

our ($MAKE_PATH, $MAKE);
BEGIN {
    $MAKE_PATH = $ENV{MAKE_PATH} || 'make';
    if ($MAKE_PATH =~ /\w*make\w*/i) {
        $MAKE = $&;
    } else {
        $MAKE = 'make';
    }
}

our @TempFiles;

sub run_test_make ($) {
    my $block = shift;

    my $tempdir = tempdir();
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    my $filename = $block->filename;
    my $source   = $block->source;
    $filename = create_file($filename, $source) if $source;

    process_pre($block);
    process_touch($block);
    process_utouch($block);

    my ($errcode, $output, $stdout, $stderr) =
        run_make($block, $filename);

    clean();
    chdir $saved_cwd;
    #warn "\nfull: $output\nstderr: $stderr\nstdout: $stdout\n";

    process_output($block, $errcode, $output, $stdout, $stderr);
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
    print $fh $content;
    close $fh;
    return $filename;
}

sub process_pre ($) {
    my $code = $_[0]->pre;
    return if not $code;
    eval $code;
    confess "error in `pre' section: $@" if $@;
}

sub process_touch ($) {
    my $block = shift;
    my $buf = $block->touch;
    return if not $buf;
    touch(split /\s+/, $buf);
}

sub touch (@)
{
  for my $name (@_) {
      my $fh;
      open $fh, ">> $name" and print $fh "\n" and close $fh
	      or confess("couldn't touch $name: $!");
      mark_temp($name);
  }
}

sub mark_temp {
    push @TempFiles, @_;
}

sub process_utouch ($) {
    my $block = shift;
    my $buf = $block->utouch;
    return if not $buf;
    utouch(split /\s+/, $buf);
}

# Touch with a time offset.  To DTRT, call touch() then use stat() to get the
# access/mod time for each file and apply the offset.


sub utouch ($@)
{
  my $offset = shift;
  touch(@_);
  my @s = stat $_[0];
  utime($s[8]+$offset, $s[9]+$offset, @_);
}

sub run_make($$) {
    my ($block, $filename) = @_;
    my $options  = $block->options || '';
    my $goals    = $block->goals || '';

    if ($filename) {
        $options = "-f $filename $options";
    }
    my $cmd = "$MAKE_PATH $options $goals";
    my( $success, $errcode, $routput, $rstdout, $rstderr ) =
            IPC::Cmd::run( command => $cmd, verbose => 0 );
    local $" = '';
    return ($errcode, "@$routput", "@$rstdout", "@$rstderr");
}

sub process_output ($$$$$) {
    my ($block, $errcode, $output, $stdout, $stderr) = @_;

    my $stdout2  = $block->stdout;
    my $stderr2  = $block->stderr;
    my $output2  = $block->output;
    my $errcode2 = $block->error_code;

    if ($errcode2 and $errcode2 =~ /\d+/s) {
        $errcode2 = $&;
    }

    my $name = $block->name;
    is $errcode, $errcode2, "Error Code - $name" if defined $errcode2;
    is $output, $output2, "Full Output Buffer - $name" if defined $output2;
    is $stdout, $stdout2, "stdout - $name" if defined $stdout2;
    is $stderr, $stderr2, "stderr - $name" if defined $stderr2;
}

sub clean {
    for my $tmpfile (@TempFiles) {
        unlink $tmpfile;
    }
    @TempFiles = ();
}

END {
    &clean;
}

package t::Parser::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

1;

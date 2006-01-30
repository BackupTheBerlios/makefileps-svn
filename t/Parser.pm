#: t/Parser.pm
#: Tester based on Test::Base
#: 2006-01-29 2006-01-30

package t::Parser;
use Test::Base -Base;

use File::Temp qw[ tempdir tempfile ];
use Cwd ();
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

our @TempFiles;

sub run_exe ($) {
    my $block = shift;
    my $name = $block->name;
    my $source   = $block->source;
    my $filename = $block->filename;
    my $stdout2  = $block->stdout;
    my $stderr2  = $block->stderr;
    my $output2  = $block->output;
    my $errcode2 = $block->error_code;

    if ($errcode2 and $errcode2 =~ /\d+/s) {
        $errcode2 = $&;
    }
    return if not $stdout2 and not $stderr2;

    my $tempdir = tempdir();
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    $filename = create_file($tempdir, $filename, $source);
    process_touch($block);
    process_utouch($block);

    my ($errcode, $output, $stdout, $stderr) =
        run_make($block, $filename);
    chdir $saved_cwd;

    clean();
    #warn "\nfull: $output\nstderr: $stderr\nstdout: $stdout\n";

    is $errcode, $errcode2, "Error Code - $name" if defined $errcode2;
    is $output, $output2, "Full Output Buffer - $name" if defined $output2;
    is $stdout, $stdout2, "stdout - $name" if defined $stdout2;
    is $stderr, $stderr2, "stderr - $name" if defined $stderr2;
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

sub run_make($$) {
    my ($block, $filename) = @_;
    my $options  = $block->options || '';
    my $goals    = $block->goals || '';
    my $cmd = "$MAKE -f $filename $goals $options";
    my( $success, $errcode, $routput, $rstdout, $rstderr ) =
            IPC::Cmd::run( command => $cmd, verbose => 0 );
    local $" = '';
    return ($errcode, "@$routput", "@$rstdout", "@$rstderr");
}

sub create_file ($$$) {
    my ($tempdir, $filename, $content) = @_;
    my $fh;
    if (not $filename) {
        ($fh, $filename) = tempfile( "create_file_XXXXX", DIR => $tempdir, UNLINK => 1 );
    } else {
        $filename = "$tempdir/$filename";
        open $fh, ">$filename" or
            confess("can't open $filename for writing: $!");
    }
    print $fh $content;
    close $fh;
    return $filename;
}

# Touch with a time offset.  To DTRT, call touch() then use stat() to get the
# access/mod time for each file and apply the offset.

sub touch (@)
{
  for my $name (@_) {
      my $fh;
      open $fh, ">> $name" and print $fh "\n" and close $fh
	      or confess("couldn't touch $name: $!");
      push @TempFiles, $name;
  }
}

sub utouch ($@)
{
  my $offset = shift;
  touch(@_);
  my @s = stat $_[0];
  utime($s[8]+$offset, $s[9]+$offset, @_);
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

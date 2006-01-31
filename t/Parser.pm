#: t/Parser.pm
#: Tester based on Test::Base
#: 2006-01-29 2006-01-31

package t::Parser;
use Test::Base -Base;

our @EXPORT = qw(
    run_test_make util_path set_make
    $RM_F $ECHO_ENV $MAKE
);

use File::Temp qw[ tempdir tempfile ];
use Cwd ();
use File::Spec ();
use IPC::Cmd;
use Text::Balanced qw[ extract_delimited extract_multiple ];
use FindBin;
#use Data::Dumper::Simple;

our $UTIL_PATH;
our $ECHO_ENV;
our $RM_F;
our $PERL;

sub util_path ($) {
    $UTIL_PATH = File::Spec->catdir($FindBin::Bin, $_[0]);
    $ECHO_ENV = "$PERL " . File::Spec->catfile($UTIL_PATH, 'echo_env.pl');
    $RM_F     = "$PERL " . File::Spec->catfile($UTIL_PATH, 'rm_f.pl');
}

sub clean_env () {
  # Get a clean environment

  my %makeENV = ();
  # Pull in benign variables from the user's environment
  #
  foreach (# UNIX-specific things
           'TZ', 'LANG', 'TMPDIR', 'HOME', 'USER', 'LOGNAME', 'PATH',
           # Purify things
           'PURIFYOPTIONS',
           # Windows NT-specific stuff
           'Path', 'SystemRoot',
           # DJGPP-specific stuff
           'DJDIR', 'DJGPP', 'SHELL', 'COMSPEC', 'HOSTNAME', 'LFN',
           'FNCASE', '387', 'EMU387', 'GROUP',
           'GNU_MAKE_PATH', 'MAKE_PATH',
          ) {
    $makeENV{$_} = $ENV{$_} if $ENV{$_};
  }
  %ENV = ();
  %ENV = %makeENV;
}

our ($MAKE, $MAKE_PATH);

sub set_make ($$) {
    my ($env_name, $default) = @_;
    $MAKE_PATH = $ENV{$env_name} || $MAKE_PATH || $default;
    if ($MAKE_PATH =~ /\w*make\w*/i) {
        $MAKE = $&;
    } else {
        $MAKE = 'make';
    }
}

BEGIN {
    if ($^O =~ / /) {
        $PERL = 'perl';
    } else {
        $PERL = $^X;
    }
    #warn $PERL;

    set_make('MAKE_PATH', 'make');

    # Get a clean environment
    clean_env();
}

our @TempFiles;

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

    my ($errcode, $full_output, $stdout, $stderr) =
        run_make($block, $filename);

    process_post($block);
    process_found($block);
    process_not_found($block);

    clean();
    chdir $saved_cwd;
    #warn "\nstderr: $stderr\nstdout: $stdout\n";

    process_output($block, $errcode, $stdout, $stderr);
}

sub preprocess ($) {
    return if not defined $_[0];
    subs_var($_[0], 'ECHO_ENV', $ECHO_ENV);
    subs_var($_[0], 'RM_F',     $RM_F    );
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
    print $fh $content;
    close $fh;
    return $filename;
}

sub process_pre ($) {
    my $block = shift;
    my $code = $block->pre;
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
        $options = "-f '$filename' $options";
    }
    my $cmd = [ split_args($MAKE_PATH), split_args($options), split_args($goals) ];
    #warn Dumper($cmd);
    my( $success, $errcode, $routput, $rstdout, $rstderr ) =
            IPC::Cmd::run( command => $cmd, verbose => 0 );
    local $" = '';
    return ($errcode, "@$routput", "@$rstdout", "@$rstderr");
}

sub split_args ($) {
    my $text = shift;
    my @flds = extract_multiple(
        $text,
        [ sub { extract_delimited($_[0], q{"'}) }, qr/\S+/ ],
        undef,
        0,
    );
    #warn Dumper(@flds);
    my @res = grep { 
        s/^\s+|\s+$//g;
        s/^'(.*)'$/$1/g;
        s/^"(.*)"$/$1/g;
        $_;
    } @flds;
    #warn Dumper(@res);
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

sub process_post ($) {
    my $block = shift;
    my $code = $block->post;
    return if not $code;
    eval $code;
    confess "error in `post' section: $@" if $@;
}

sub process_found ($) {
    my $block = shift;
    my $buf = $block->found;
    return if not $buf;
    my @files = split /\s+/s, $buf;
    for my $file (@files) {
        ok -f $file, "File $file should be found - " . $block->name();
    }
}

sub process_not_found ($) {
    my $block = shift;
    my $buf = $block->not_found;
    return if not $buf;
    my @files = split /\s+/s, $buf;
    for my $file (@files) {
        ok ! -f $file, "File $file should NOT be found - " . $block->name();
    }
}

sub clean () {
    for my $tmpfile (@TempFiles) {
        unlink $tmpfile;
    }
    @TempFiles = ();
}

END {
    clean();
}

package t::Parser::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

1;

#: t/Backend/Util.pm
#: utilities used in t::Backend::Base
#: 2006-02-01 2006-02-03

package t::Backend::Util;

use t::Util -Base;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    process_args
    touch utouch
    mark_temp clean_temp
    clean_env
);

our @TempFiles;

sub process_args ($) {
    my $text = shift;
    my @args = split_arg($text);
    foreach (@args) {
        #warn "----------\n";
        #warn Dumper(@args, $_);
        #warn "----------\n";
        if (/^"(.*)"$/) {
            #warn "---------";
            #warn qq{Pusing "$1" into args\n};
            $_ = $1;
            process_escape( $_, q{"\\$@\#} );
        } elsif (/^'(.*)'$/) {
            #warn "  Pusing '$1' into args\n";
            $_ = $1;
        }
    }
    return @args;
}

sub touch (@) {
  for my $name (@_) {
      my $fh;
      open $fh, ">> $name" and print $fh "\n" and close $fh
	      or confess("couldn't touch $name: $!");
      mark_temp($name);
  }
}

# Touch with a time offset.  To DTRT, call touch() then use stat() to get the
# access/mod time for each file and apply the offset.

sub utouch (@) {
  my $offset = shift;
  touch(@_);
  my @s = stat $_[0];
  utime($s[8]+$offset, $s[9]+$offset, @_);
}

sub mark_temp (@) {
    push @TempFiles, @_;
}

sub clean_temp () {
    for my $tmpfile (@TempFiles) {
        unlink $tmpfile;
    }
    @TempFiles = ();
}

# the current implementation of clean_env is buggy. haven't found a better approach
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
           'Path', 'SystemRoot', 'TMP', 'SystemDrive', 'TEMP', 'OS', 'HOMEPATH',
           # DJGPP-specific stuff
           'DJDIR', 'DJGPP', 'SHELL', 'COMSPEC', 'HOSTNAME', 'LFN',
           'FNCASE', '387', 'EMU387', 'GROUP',
           'GNU_MAKE_PATH', 'GNU_SHELL_PATH', 'INC', 'path',
          ) {
    $makeENV{$_} = $ENV{$_} if defined $ENV{$_};
  }
  %ENV = ();
  %ENV = %makeENV;
}

1;

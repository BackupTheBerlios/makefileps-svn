package t::Backend::Util;

use strict;
use warnings;
use t::Util -Base;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    touch utouch
    mark_temp clean_temp
    clean_env
);

our @TempFiles;

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
           'GNU_MAKE_PATH', 'GNU_SHELL_PATH', 'INC',
          ) {
    $makeENV{$_} = $ENV{$_} if defined $ENV{$_};
  }
  %ENV = ();
  %ENV = %makeENV;
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

END {
    clean_temp();
}

1;

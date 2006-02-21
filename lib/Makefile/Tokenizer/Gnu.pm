#: Makefile/Tokenizer/Gnu.pm
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-21 2006-02-21

package Makefile::Tokenizer::Gnu;

use strict;
use warnings;

our $VERSION = '1.00';

our $Error;

sub new {
    my $proto = shift;
	my $class = ref $proto || $proto;

	# Create the empty tokenizer struct
	my $self = bless {
		# Source code
		source         => undef,

        # Output token buffer
		tokens         => [],
    }, $class;

    my $arg = shift;

	if ( not defined $arg ) {
		# We weren't given anything
		_error( "No source provided to Tokenizer" );
        return undef;
    } elsif ( not ref $arg ) {
		my $source = _slurp($arg);
		if ( $source ) {
			# Content returned by reference
			$self->{source} = $$source;
		} else {
			# Errors returned as a string
			return undef;
		}
	} elsif ( ref $arg eq 'SCALAR' ) {
		$self->{source} = $$arg;
    } elsif ( ref $arg eq 'ARRAY') ) {
		$self->{source} = join "\n", @$arg;
	} else {
		# We don't support whatever this is
		_error( ref($arg), " is not supported as a source provider" );
        return undef;
	}
    return $self;
}

sub get_token {
	my $self = shift;
}

sub all_tokens {
    my $self = shift;
}

sub errstr {
    return $Error;
}

sub _error {
    $Error = join('', @_);
}

sub _slurp {
    my $fname = shift;
    open my $in, $fname;
    if (not $in) {
        _error("Can't open $fname for reading: $!");
        return undef;
    }
    local $/;
    my $buf = <$in>;
    close $in;
    return $buf;
}

1;
__END__

=head1 NAME

Makefile::Tokenizer::Gnu - The GNU make Makefile Tokenizer

=head1 VERSION

This document describes Makefile::Tokenizer::Gnu released on March XX, 2006.

=head1 SYNOPSIS

  # Create a tokenizer for a file, array or string
  $Tokenizer = Makefile::Tokenizer::Gnu->new( 'filename.pl' );
  $Tokenizer = Makefile::Tokenizer::Gnu->new( \@lines       );
  $Tokenizer = Makefile::Tokenizer::Gnu->new( \$source      );
  
  # Return all the tokens for the document
  my $tokens = $Tokenizer->all_tokens;
  
  # Or we can use it as an iterator
  while ( my $Token = $Tokenizer->get_token ) {
  	print "Found token '$Token'\n";
  }
  
=head1 DESCRIPTION

Makefile::Tokenizer::Gnu is the class that provides Tokenizer objects for use in
breaking strings of Perl source code into Tokens.

=head1 METHODS

=over

=item $token = $obj->get_token

When using the Makefile::Tokenizer::Gnu object as an iterator, 
the C<get_token> method is the primary method that is used. 
It increments the cursor and returns the next Token in the output
array.

The actual parsing of the file is done only as-needed, and a line at
a time. When C<get_token> hits the end of the token array, it will
cause the parser to pull in the next line and parse it, continuing
as needed until there are more tokens on the output array that
get_token can then return.

This means that a number of Tokenizer objects can be created, and
won't consume significant CPU until you actually begin to pull tokens
from it.

Return a L<PPI::Token> object on success, C<0> if the Tokenizer had
reached the end of the file, or C<undef> on error.

=item $str = $obj->errstr

Return the error message of the last failed operation.

=back

=head1 SEE ALSO

L<Makefile::Parser::Gnu>, L<Makefile::Token>.

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

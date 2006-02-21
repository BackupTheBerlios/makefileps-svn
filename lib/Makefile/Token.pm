#: Makefile/Token.pm
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-21 2006-02-21

package Makefile::Token;

use strict;
use warnings;
use base 'Makefile::Element';

our $VERSION = '1.00';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {
        content => $_[0],
    }, $class;
    return $self;
}

sub _set_class {
}

sub content {
	$_[0]->{content};
}

sub set_content {
	$_[0]->{content} = $_[1];
}

sub add_content { $_[0]->{content} .= $_[1] }

sub length { &CORE::length($_[0]->{content}) }

1;
__END__

=head1 NAME

Makefile::Token - A single token of Makefile source code

=head1 VERSION

This document describes Makefile::Token 1.00 released on March XX, 2006.

=head1 INHERITANCE

  Makefile::Token
  isa Makefile::Element

=head1 DESCRIPTION

C<Makefile::Token> is the abstract base class for all Tokens. In Makefile::Parser terms,
a "Token" is a L<Makefile::Element> that directly represents bytes of source code.

=head1 METHODS

=over

=item $obj = Makefile::Token->new

XXX

=item $obj->content

Return the string in a Token.

=item $obj->set_content($string)

The C<set_content> method allows to set/change the string that the
C<PPI::Token> object represents.

Returns the string you set the Token to

=item $obj->add_content($string)

The C<add_content> method allows you to add additional bytes of code
to the end of the Token.

Returns the new full string after the bytes have been added.

=item $len = $obj->length

The C<length> method returns the length of the string in a Token.

=back

=head1 SEE ALSO

L<Makefile::Element>, L<Makefile::Tokenizer>.

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

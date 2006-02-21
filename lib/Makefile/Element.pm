#: Makefile/Element.pm
#: The abstract Element class, a base for all source objects
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-21 2006-02-21

package Makefile::Element;

use strict;
use warnings;

our $VERSION = '1.00';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {
    }, $class;
    return $self;
}

1;
__END__

=head1 NAME

Makefile::Element - The abstract Element class, a base for all source objects

=head1 VERSION

This document describes Makefile::Token 1.00 released on March XX, 2006.

=head1 INHERITANCE

  Makefile::Element is the root of the MDOM tree

=head1 DESCRIPTION

The abstract C<Makefile::Element> serves as a base class for all source-related
objects, from a single whitespace token to an entire document. It provides
a basic set of methods to provide a common interface and basic
implementations.

=head1 METHODS

=over

=item *

=back

=head1 SEE ALSO

L<Makefile::Parser>.

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

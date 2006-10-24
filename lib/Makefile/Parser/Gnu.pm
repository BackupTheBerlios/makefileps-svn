#: Makefile/Parser/Gnu.pm
#: Full-fledged parser for GNU make Makefiles
#: Copyright (c) 2006 Agent Zhang
#: 2006-02-21 2006-02-21

package Makefile::Parser::Gnu;

use strict;
use warnings;

use Makefile::Gnu::AST;
use MK::DOM;

our $VERSION = '1.00';

sub parse {
    my $self->shift;
    my $input = shift;
    my $in;
    if (ref $input) {
        open $in, '<', $input or die;
    } else {
        open $in, $input or
            die "Can't open $input for reading: $!";
    }
    my $ast = $self->_parse($in);
    close $in;
    $ast;
}

sub _parse {
    shift;
    my $fh = shift;
}

sub desugar {
    shift;
    my $dom = shift;
    my $ast;
    return $ast;
}

1;
__END__

=head1 NAME

Makefile::Parser::Gnu - Full-fledged parser for GNU make Makefiles

=head1 VERSION

This document describes Makefile::Parser::Gnu 1.00 released on March XX, 2006.

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a GNU make 3.81beta4 compatible parser written in pure Perl.

=head1 METHODS

=over

=item $obj = $class->new;

=item $obj2 = $obj1->new;

=item $obj = $class->new(...);

=item $obj->parse(...);

=back

=head1 SEE ALSO

L<Makefile::Parser>, GNU make Manual L<http://www.gnu.org/software/make/manual/make.html>

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

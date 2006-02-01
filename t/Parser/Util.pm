package t::Parser::Util;

use strict;
use warnings;
use base 'Exporter';
#use Data::Dumper::Simple;

our @EXPORT_OK = qw(
    split_args
);

use Text::Balanced qw( extract_delimited extract_multiple );

sub split_args ($) {
    my $text = shift;
    my @flds = extract_multiple(
        $text,
        [ sub { extract_delimited($_[0], q{"'}) }, qr/\s*\S+/ ],
        undef,
        1,
    );
    #warn Dumper($text, @flds);
    my @res = grep {
        s/^\s+|\s+$//g;
        s/^'(.*)'$/$1/g;
        s/^"(.*)"$/$1/g;
        defined $_ and $_ ne '';
    } @flds;
    #warn Dumper(@res);
    return @res;
}

1;

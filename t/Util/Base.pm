#: t/Util/Base.pm
#: facilities used by script/sh and also shared by the testers
#: 2006-02-03 2006-02-03

package t::Util::Base;

use Spiffy -Base;
use Text::Balanced qw( gen_delimited_pat );

our @EXPORT = qw(
    split_arg process_escape
);

our $DelimPat;

BEGIN {
    $DelimPat = gen_delimited_pat(q{"});
}

sub extract_many (@) {
    my $text = shift;
    my @flds;
    while (1) {
        #warn '@flds = ', Dumper(@flds);
        if ($text =~ /\G\s* ( (?:\\.)+ [^'"\s]* )/gcox) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*('[^']*')/gco) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*($DelimPat)/gco) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*( \S (?:[^'"\s\\]|\\.)* )/gcox) {
            push @flds, $1;
        } else {
            last;
        }
    }
    return @flds;
}

sub split_arg ($) {
    my $text = shift;
    return () if not defined $text;
    #my @flds = extract_multiple(
    #    $text,
    #    [
    #        qr/\G\s*\\./,
    #        qr/\G\s*'[^']*'/,
    #        qr/\G\s*$DelimPat/,
    #        qr/\G\s*\S[^'"\s]*/,
    #    ],
    #    undef,
    #    1,
    #);
    my @flds = extract_many($text);
    #@flds = grep { s/^\s+|\s+$//g; defined($_) && $_ ne '' } @flds;
    #warn "\n======================\n";
    #warn Dumper($text, @flds);
    #warn "======================\n";
    return @flds;
}

sub process_escape (@) {
    return if $_[0] !~ /\\/;
    my $list = quotemeta $_[1];
    $_[0] =~ s/\\[$list]/substr($&,1,1)/eg;
}

1;

#: t/Util.pm
#: utilities shared among testers
#: 2006-02-02 2006-02-02

package t::Util;

use Spiffy -Base;
use Carp qw( confess );
use Test::More;
use IPC::Cmd;
use Text::Balanced qw( gen_delimited_pat );
#use Data::Dumper::Simple;

our @EXPORT = qw(
    run_shell split_arg join_list
    split_arg process_escape gen_escape_pat
    process_pre process_post
    process_found process_not_found
);

our $DelimPat;

BEGIN {
    $DelimPat = gen_delimited_pat(q{"});
}

sub join_list (@) {
    my @args = @_;
    for (@args) {
        if (ref $_ eq 'ARRAY') {
            $_ = join('', @$_);
        }
    }
    return wantarray ? @args : $args[0];
}

# returns ($error_code, $stdout, $stderr)
sub run_shell ($@) {
    my ($cmd, $verbose) = @_;
    $IPC::Cmd::USE_IPC_RUN = 1;
    my @res = IPC::Cmd::run( command => $cmd, verbose => $verbose );
    #warn "^^^ Output: $res[2][0]";
    return (join_list @res[1, 3, 4]);
}

sub extract_many (@) {
    my $text = shift;
    my @flds;
    while (1) {
        #warn '@flds = ', Dumper(@flds);
        if ($text =~ /\G\s*(\\.)/gc) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*('[^']*')/gc) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*($DelimPat)/gc) {
            push @flds, $1;
        } elsif ($text =~ /\G\s*(\S[^'"\s]*)/gc) {
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

sub process_escape ($$) {
    return if $_[0] !~ /\\/;
    my $pat = gen_escape_pat($_[1]);
    $_[0] =~ s/$pat/substr($&,1,1)/eg;
}

sub gen_escape_pat ($) {
    my $list = quotemeta $_[0];
    return qr/ \\ [ $list ] /x;
}

sub process_pre ($) {
    my $block = shift;
    my $code = $block->pre;
    return if not $code;
    {
        package main;
        eval $code;
    }
    confess "error in `pre' section: $@" if $@;
}

sub process_post ($) {
    my $block = shift;
    my $code = $block->post;
    return if not $code;
    {
        package main;
        eval $code;
    }
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

1;

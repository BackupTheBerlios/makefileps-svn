#: t/Util.pm
#: utilities shared among testers
#: 2006-02-02 2006-02-02

package t::Util;

use Spiffy -Base;
use IPC::Cmd;
use Text::Balanced qw( extract_delimited extract_multiple );
use Data::Dumper::Simple;

our @EXPORT = qw( run_shell split_arg join_list );

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

sub split_arg ($) {
    my $text = shift;
    #warn Dumper($text);
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

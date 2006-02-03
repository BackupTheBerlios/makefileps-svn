#: t/Util.pm
#: utilities shared among testers
#: 2006-02-02 2006-02-02

package t::Util;

use t::Util::Base -Base;
use Carp qw( confess );
use Test::More;
use IPC::Cmd;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    run_shell split_arg join_list
    process_pre process_post
    process_found process_not_found
);

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

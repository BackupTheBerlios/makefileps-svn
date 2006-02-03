#: t/Util.pm
#: utilities shared among testers
#: 2006-02-02 2006-02-03

package t::Util;

use t::Util::Base -Base;
use Carp qw( confess );
use IPC::Cmd;
#use Data::Dumper::Simple;

our @EXPORT = qw(
    test_shell_command run_shell
    split_arg join_list
    process_pre process_post
    process_found process_not_found
);

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
        Test::More::ok(
            -f $file, 
            "File $file should be found - ".$block->name
        );
    }
}

sub process_not_found ($) {
    my $block = shift;
    my $buf = $block->not_found;
    return if not $buf;
    my @files = split /\s+/s, $buf;
    for my $file (@files) {
        Test::More::ok(
            ! -f $file,
            "File $file should NOT be found - ".$block->name
        );
    }
}

sub compare ($$$) {
    my ($got, $expected, $desc) = @_;
    return if not defined $expected;
    if ($desc =~ /\w+_like/) {
        Test::More::like($got, qr/$expected/s, $desc);
    } else {
        Test::More::is($got, $expected, $desc);
    }
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

sub test_shell_command ($$@) {
    my $block    = shift;
    my $cmd      = shift;
    my %filters  = @_;
    return if not defined $cmd;

    my ($success, $errcode, $full, $stdout, $stderr)
        = join_list IPC::Cmd::run( command => $cmd );

    my $errcode2 = $block->error_code;
    if ($errcode2 and $errcode2 =~ /\d+/s) {
        $errcode2 = $&;
    }

    my $success2 = $block->success;
    if ($success2 and $success2 =~ /\w+/s) {
        $success2 = lc($&);
    }

    my $name = $block->name;

    while (my ($key, $val) = each %filters) {
        if ($key =~ /stdout|stderr/) {
            no strict 'refs';
            $val->(${"$key"}) if ref $val eq 'CODE';
        }
    }

    compare $stdout, $block->stdout, "stdout - $name";
    compare $stdout, $block->stdout_like, "stdout_like - $name";
    compare $stderr, $block->stderr, "stderr - $name";
    compare $stderr, $block->stderr_like, "stderr_like - $name";
    compare $errcode, $errcode2, "error_code - $name";
    compare (
        $success ? 'true' : 'false',
        $success2,
        "success - $name",
    );
}

# returns ($error_code, $stdout, $stderr)
sub run_shell (@) {
    my ($cmd, $verbose) = @_;
    #$IPC::Cmd::USE_IPC_RUN = 1;
   
    #confess Dumper($cmd);
    my @res = IPC::Cmd::run( command => $cmd, verbose => $verbose );
    #warn "HERE!";
    #warn "^^^ Output: $res[2][0]";
    return (join_list @res[1, 3, 4]);
}

1;

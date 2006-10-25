package MDOM::Document::Gmake;

use strict;
use warnings;

use Text::Balanced qw( gen_extract_tagged );
use MDOM;
use Data::Dump::Streamer;
use base 'MDOM::Node';

use constant {
    COMMENT => 1,
    COMMAND => 2,
    RULE    => 3,
    VOID    => 4,
};


my $interp_pat = gen_extract_tagged('$[({]','$[)}]');
my $context;

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $input = shift;
    return undef if !defined $input;
    my $in;
    if (ref $input) {
        open $in, '<', $input or die;
    } else {
        open $in, $input or
            die "Can't open $input for reading: $!";
    }
    my $toplevel = _tokenize($in);
    my $self = $class->SUPER::new;
    $self->__add_elements(@$toplevel);
    $self;
}

sub _tokenize {
    my ($fh) = @_;
    my @toplevel;
    my $saved_context;
    $context = VOID;
    my @tokens;
    while (<$fh>) {
        warn "!!! tokenizing $_";
        $_ .= "\n" if !/\n$/s;
        if ($context == VOID || $context == RULE) {
            if (s/^\t//) {
                @tokens = _tokenize_command($_);
                unshift @tokens, MDOM::Token::Separator->new("\t");
                if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    $saved_context = $context;
                    $context = COMMAND;
                }
                my $cmd = MDOM::Command->new;
                $cmd->__add_elements(@tokens);
                push @toplevel, $cmd;
                next;
            } else {
                @tokens = _tokenize_normal($_);
                if (@tokens >= 2 && $tokens[-1]->isa('MDOM::Token::Continuation') &&
                        $tokens[-2]->isa('MDOM::Token::Comment')) {
                    $saved_context = $context;
                    $context = COMMENT;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                }
            }
            #_dump_tokens(@tokens);
            #_dump_tokens2(@tokens);
            push @toplevel, _parse_normal(@tokens);
        } elsif ($context == COMMENT) {
            @tokens = _tokenize_comment($_);
            if (! $tokens[-1]->isa('MDOM::Token::Continuation')) {
                $context = $saved_context;
            } else {
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
            }
            $toplevel[-1]->add_content(join '', @tokens);
        } elsif ($context == COMMAND) {
            @tokens = _tokenize_command($_);
            if (! $tokens[-1]->isa('MDOM::Token::Continuation')) {
                $context = RULE;
            }
            $toplevel[-1]->__add_elements(@tokens);
        }
    }
    \@toplevel;
}

sub _tokenize_normal {
    local $_ = shift;
    my @tokens;
    my $token = '';
    my $next_token;
    while (1) {
        #warn '@tokens = ', Dumper(@tokens);
        if (/(?x) \G [\s\n]+ /gc) {
            warn "!#@$@#@#@#" if $& eq "\n";
            $next_token = MDOM::Token::Whitespace->new($&);
            #push @tokens, $next_token;
        } elsif (/(?x) \G (?: := | \?= | \+= | [=:;] )/gc) {
            $next_token = MDOM::Token::Separator->new($&);
        } elsif (/(?x) \G $interp_pat/ogc) {
            $next_token = MDOM::Token::Interpolation->new($&);
        } elsif (/(?x) \G \\ (.) /gcs) {
            my $c = $1;
            if ($c eq "\n") {
                push @tokens, MDOM::Token::Bare->new($token) if $token;
                push @tokens, MDOM::Token::LineContinuation->new("\\\n");
                return @tokens;
            } else {
                $token .= "\\$c";
            }
        } elsif (/(?x) \G (\# [^\n]*) \\ \n/sgc) {
            my $s = $1;
            push @tokens, MDOM::Token::Bare->new($token) if $token;
            push @tokens, MDOM::Token::Comment->new($s);
            push @tokens, MDOM::Token::LineContinuation->new("\\\n");
            return @tokens;
        } elsif (/(?x) \G \# [^\n]* /gc) {
            $next_token = MDOM::Token::Comment->new($&);
        } elsif (/(?x) \G . /gc) {
            #warn "!#@$@#@#@#" if $& eq "\n";
            $token .= $&;
        } else {
            last;
        }
        if ($next_token) {
            if ($token) {
                push @tokens, MDOM::Token::Bare->new($token);
                $token = '';
            }
            push @tokens, $next_token;
            $next_token = undef;
        }
    }
    @tokens;
}

sub _tokenize_command {
    _tokenize_normal(@_);
}

sub _parse_normal {
    my @tokens = @_;
    my @seq = grep { $_->isa('MDOM::Token::Seperator') }
    my $rule = MDOM::Rule::Simple->new;
    $rule->__add_elements(@tokens);
    $rule;
}

sub _dump_tokens {
    my @tokens = map { $_->clone } @_;
    warn "??? ", (join ' ', map { s/\\/\\\\/g; s/\n/\\n/g; s/\t/\\t/g; "[$_]" } @tokens), "\n";
}

sub _dump_tokens2 {
    my @tokens = map { $_->clone } @_;
    Dump(@tokens)->To(\*STDERR)->Out();
}

1;

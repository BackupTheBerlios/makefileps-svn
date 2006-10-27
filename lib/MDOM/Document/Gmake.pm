package MDOM::Document::Gmake;

use strict;
use warnings;

use Text::Balanced qw( gen_extract_tagged );
use MDOM;
use Data::Dump::Streamer;
use base 'MDOM::Node';
use List::MoreUtils qw( before all );
use List::Util qw( first );

my %_map;
BEGIN {
    %_map = (
        COMMENT => 1,
        COMMAND => 2,
        RULE    => 3,
        VOID    => 4,
        UNKNOWN => 5,
    );
}

use constant \%_map;

my %_rev_map = reverse %_map;

my $extract_interp_1 = gen_extract_tagged('\$[(]', '[)]');
my $extract_interp_2 = gen_extract_tagged('\$[{]', '[}]');

sub extract_interp {
    my $res = $extract_interp_1->($_[0]);
    if (!$res) {
        $res = $extract_interp_2->($_[0]);
    }
    $res;
}

my ($context, $saved_context);

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
    my $self = $class->SUPER::new;
    $self->_tokenize($in);
    $self;
}

sub _tokenize {
    my ($self, $fh) = @_;
    $context = VOID;
    my @tokens;
    while (<$fh>) {
        #warn "!!! tokenizing $_";
        #warn "CONTEXT = ", $_rev_map{$context};
        $_ .= "\n" if !/\n$/s;
        if ($context == VOID || $context == RULE) {
            if ($context == VOID && s/(?x) ^ (\t\s*) (?= \# ) //) {
                @tokens = (
                    MDOM::Token::Whitespace->new($1),
                    _tokenize_comment($_)
                );
                if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    $saved_context = $context;
                    $context = COMMENT;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                }
                $self->__add_elements( @tokens );
            }
            elsif (s/^\t//) {
                @tokens = _tokenize_command($_);
                unshift @tokens, MDOM::Token::Separator->new("\t");
                if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    $saved_context = $context;
                    $context = COMMAND;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                }
                my $cmd = MDOM::Command->new;
                $cmd->__add_elements(@tokens);
                $self->__add_element($cmd);
                next;
            } else {
                @tokens = _tokenize_normal($_);
                if (@tokens >= 2 && $tokens[-1]->isa('MDOM::Token::Continuation') &&
                        $tokens[-2]->isa('MDOM::Token::Comment')) {
                    #warn "trailing comments found...";
                    $saved_context = $context;
                    $context = COMMENT;
                    $tokens[-2]->add_content("\\\n");
                    pop @tokens;
                    $self->__add_elements( _parse_normal(@tokens) );
                } elsif ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                    #warn "continuation found...";
                    $saved_context = $context;
                    $context = UNKNOWN;
                } else {
                    #warn "line parsed....";
                    $self->__add_elements( _parse_normal(@tokens) );
                }
            }
        } elsif ($context == COMMENT) {
            @tokens = _tokenize_comment($_);
            if (! $tokens[-1]->isa('MDOM::Token::Continuation')) {
                #warn "finishing comment slurping...(switch back to ",
                #    $_rev_map{$saved_context}, ")";
                $context = $saved_context;
                my $last = pop @tokens;
                $self->last_token->add_content(join '', @tokens);
                $self->last_token->parent->__add_element($last);
            } else {
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                $self->last_token->add_content(join '', @tokens);
            }
        } elsif ($context == COMMAND) {
            @tokens = _tokenize_command($_);
            if (! $tokens[-1]->isa('MDOM::Token::Continuation')) {
                $context = RULE;
                my $last = pop @tokens;
                $self->last_token->add_content(join '', @tokens);
                $self->last_token->parent->__add_element($last);
            } else {
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                $self->last_token->add_content(join '', @tokens);
            }
        } elsif ($context == UNKNOWN) {
            push @tokens, _tokenize_normal($_);
            if (@tokens >= 2 && $tokens[-1]->isa('MDOM::Token::Continuation') &&
                    $tokens[-2]->isa('MDOM::Token::Comment')) {
                $context = COMMENT;
                $tokens[-2]->add_content("\\\n");
                pop @tokens;
                $self->__add_elements( _parse_normal(@tokens) );
            } elsif ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                # do nothing here...stay in the UNKNOWN context...
            } else {
                $self->__add_elements( _parse_normal(@tokens) );
                $context = $saved_context;
            }
        } else {
            die "Unkown state: $context";
        }
    }
    if ($context != RULE && $context != VOID) {
        warn "unexpected end of input at line $.";
    }
}

sub _tokenize_normal {
    local $_ = shift;
    my @tokens;
    my $token = '';
    my $next_token;
    while (1) {
        #warn "token = $token";
        #warn extract_interp($_) if extract_interp($_);
        #warn pos;
        #warn '@tokens = ', _dump_tokens2(@tokens);
        if (/(?x) \G [\s\n]+ /gc) {
            #warn "!#@$@#@#@#" if $& eq "\n";
            $next_token = MDOM::Token::Whitespace->new($&);
            #push @tokens, $next_token;
        }
        elsif (/(?x) \G (?: := | \?= | \+= | [=:;] )/gc) {
            $next_token = MDOM::Token::Separator->new($&);
        }
        elsif (my $res = extract_interp($_)) {
            $next_token = MDOM::Token::Interpolation->new($res);
            #die "!!!???";
            #_dump_tokens($next_token);
        }
        elsif (/(?x) \G \$. /gc) {
            $next_token = MDOM::Token::Interpolation->new($&);
        }
        elsif (/(?x) \G \\ (.) /gcs) {
            my $c = $1;
            if ($c eq "\n") {
                push @tokens, MDOM::Token::Bare->new($token) if $token;
                push @tokens, MDOM::Token::Continuation->new("\\\n");
                return @tokens;
            } else {
                $token .= "\\$c";
            }
        }
        elsif (/(?x) \G (\# [^\n]*) \\ \n/sgc) {
            my $s = $1;
            push @tokens, MDOM::Token::Bare->new($token) if $token;
            push @tokens, MDOM::Token::Comment->new($s);
            push @tokens, MDOM::Token::Continuation->new("\\\n");
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
    local $_ = shift;
    my @tokens;
    if (/(?x) \G (\s*) ([\@+\-]) /gc) {
        my ($whitespace, $modifier) = ($1, $2);
        if ($whitespace) {
            push @tokens, MDOM::Token::Whitespace->new($whitespace);
        }
        push @tokens, MDOM::Token::Modifier->new($modifier);
    }
    my $strlen = length;
    my $token = '';
    my $next_token;
    while (1) {
        #warn '@tokens = ', Dumper(@tokens);
        #warn "TOKEN = *$token*\n";
        #warn "LEFT: *", (substr $_, pos $_), "*\n";
        my $last = 0;
        if (/(?x) \G \n /gc) {
            #warn "!!!";
            $next_token = MDOM::Token::Whitespace->new("\n");
            #push @tokens, $next_token;
        }
        elsif (my $res = extract_interp($_)) {
            $next_token = MDOM::Token::Interpolation->new($res);
        }
        elsif (/(?x) \G \$. /gc) {
            $next_token = MDOM::Token::Interpolation->new($&);
        }
        elsif (/(?x) \G \\ ([\#\\\n]) /gcs) {
            my $c = $1;
            if ($c eq "\n" and pos == $strlen) {
                $next_token = MDOM::Token::Continuation->new("\\\n");
            } else {
                $token .= "\\$c";
            }
        }
        elsif (/(?x) \G . /gc) {
            $token .= $&;
        } else {
            $last = 1;
        }
        if ($next_token) {
            if ($token) {
                push @tokens, MDOM::Token::Bare->new($token);
                $token = '';
            }
            push @tokens, $next_token;
            $next_token = undef;
        }
        last if $last;
    }
    @tokens;
}

sub _tokenize_comment {
    local $_ = shift;
    my @tokens;
    my $token = '';
    #warn "COMMENT: $_";
    while (1) {
        if (/(?x) \G \n /gc) {
            push @tokens, MDOM::Token::Comment->new($token) if $token;
            push @tokens, MDOM::Token::Whitespace->new("\n");
            return @tokens;
            #push @tokens, $next_token;
        }
        elsif (/(?x) \G \\ ([\\\n]) /gcs) {
            my $c = $1;
            if ($c eq "\n") {
                push @tokens, MDOM::Token::Comment->new($token) if $token;
                push @tokens, MDOM::Token::Continuation->new("\\\n");
                return @tokens;
            } else {
                $token .= "\\$c";
            }
        }
        elsif (/(?x) \G . /gc) {
            $token .= $&;
        }
        else {
            last;
        }
    }
}

sub _parse_normal {
    my @tokens = @_;
    my @seq = grep { $_->isa('MDOM::Token::Separator') } @tokens;
    #_dump_tokens2(@seq);
    if (@tokens == 1) {
        return $tokens[0];
    }
    elsif (@seq >= 2 && $seq[0] eq ':' and $seq[1] eq ';') {
        my $rule = MDOM::Rule::Simple->new;
        my @t = before { $_ eq ';' } @tokens;
        $rule->__add_elements(@t);
        splice @tokens, 0, scalar(@t);

        my @prefix = shift @tokens;
        if ($tokens[0] && $tokens[0]->isa('MDOM::Token::Whitespace')) {
            push @prefix, shift @tokens;
        }

        @tokens = (@prefix, _tokenize_command(join '', @tokens));
        if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
            $saved_context = $context;
            $context = COMMAND;
        }
        my $cmd = MDOM::Command->new;
        $cmd->__add_elements(@tokens);
        $rule->__add_elements($cmd);
        $saved_context = RULE;
        return $rule;
    }
    elsif (@seq >= 2 && $seq[0] eq ':' and $seq[1] eq ':') {
        my $rule = MDOM::Rule::StaticPattern->new;
        my @t = before { $_ eq ';' } @tokens;
        $rule->__add_elements(@t);
        splice @tokens, 0, scalar(@t);
        if (@tokens) {
            my @prefix = shift @tokens;
            if ($tokens[0] && $tokens[0]->isa('MDOM::Token::Whitespace')) {
                push @prefix, shift @tokens;
            }

            @tokens = (@prefix, _tokenize_command(join '', @tokens));
            if ($tokens[-1]->isa('MDOM::Token::Continuation')) {
                $saved_context = $context;
                $context = COMMAND;
            }
            my $cmd = MDOM::Command->new;
            $cmd->__add_elements(@tokens);
            $rule->__add_elements($cmd);
        }
        $saved_context = RULE;
        return $rule;
    }
    elsif (@seq == 1 && $seq[0] eq ':') {
        my $rule = MDOM::Rule::Simple->new;
        $rule->__add_elements(@tokens);
        $saved_context = RULE;
        return $rule;
    }
    elsif (@seq && ($seq[0] eq '=' || $seq[0] eq ':=')) {
        my $assign = MDOM::Assignment->new;
        $assign->__add_elements(@tokens);
        $saved_context = VOID;
        return $assign;
    }
    if (all {
                $_->isa('MDOM::Token::Comment')    ||
                $_->isa('MDOM::Token::Whitespace') 
            } @tokens) {
        @tokens;
    } else {
        # XXX directive support given here...
        my $node = MDOM::Unknown->new;
        $node->__add_elements(@tokens);
        $node;
    }
}

sub _dump_tokens {
    my @tokens = map { $_->clone } @_;
    warn "??? ", (join ' ',
        map { s/\\/\\\\/g; s/\n/\\n/g; s/\t/\\t/g; "[$_]" } @tokens
    ), "\n";
}

sub _dump_tokens2 {
    my @tokens = map { $_->clone } @_;
    Dump(@tokens)->To(\*STDERR)->Out();
}

1;

use Test::Base;

plan tests => blocks() * 2;

use MDOM::Document::Gmake;
use MDOM::Dumper;

run {
    my $block = shift;
    my $name = $block->name;
    my $src = $block->src;
    my $dom = MDOM::Document::Gmake->new( \$src );
    ok $dom, "$name - DOM defined";
    my $dumper = MDOM::Dumper->new($dom);
    my $got = $dumper->string;
    my $expected = $block->dom;
    $got =~ s/(?x) [ \t]+? (?= \' [^\n]* \' )/    /gs;
    $expected =~ s/(?x) [ \t]+? (?= \' [^\n]* \' )/    /gs;
    is $got, $expected, "$name - DOM structure ok";
    #warn $dumper->string if $name =~ /TEST 0/;
};

__DATA__

=== TEST 0:
--- src

all: ; echo "hello, world"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace   ' '
      MDOM::Token::Bare         'echo "hello, world"'
      MDOM::Token::Whitespace   '\n'



=== TEST 1:
--- src

all:
	echo "hello, world"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Bare         'echo "hello, world"'
    MDOM::Token::Whitespace   '\n'



=== TEST 2:
--- src

a: foo.c  bar.h	$(baz) # hello!
	@echo ...

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   ' '
    MDOM::Token::Bare         'foo.c'
    MDOM::Token::Whitespace   '  '
    MDOM::Token::Bare         'bar.h'
    MDOM::Token::Whitespace   '\t'
    MDOM::Token::Interpolation   '$(baz)'
    MDOM::Token::Whitespace      ' '
    MDOM::Token::Comment         '# hello!'
    MDOM::Token::Whitespace      '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Separator    '@'
    MDOM::Token::Bare         'echo ...'
    MDOM::Token::Whitespace   '\n'



=== TEST 3:
--- src

a: b # hello! \
	this is comment too! \
 so is this line

	# this is a cmd
	+touch $$

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    'b'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Comment    '# hello! \\n\tthis is comment too! \\n so is this line'
    MDOM::Token::Whitespace  '\n'
  MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Bare    '# this is a cmd'
    MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Separator    '+'
    MDOM::Token::Bare    'touch $$'
    MDOM::Token::Whitespace    '\n'



=== TEST 4:
--- src
a :
	- mv \#\
	+ e \
  \\
	@

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'a'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Separator    '-'
    MDOM::Token::Bare    ' mv \#\\n\t+ e \\n  \\'
    MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Separator    '@'
    MDOM::Token::Whitespace    '\n'



=== TEST 5:
--- src
--- dom
MDOM::Document::Gmake

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

=== TEST 1: "hello world" one-linner
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



=== TEST 2: "hello world" makefile
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



=== TEST 3: variable references in prereq list
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



=== TEST 4: line continuations in comments
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
    MDOM::Token::Bare    'touch '
    MDOM::Token::Interpolation '$$'
    MDOM::Token::Whitespace    '\n'



=== TEST 5: line continuations in commands
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



=== TEST 6: empty makefile
--- src
--- dom
MDOM::Document::Gmake



=== TEST 7: line continuations in prereq list and weird target names
--- src

@a:\
	 @b   @c

@b : ;
@c:;;

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         '@a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Continuation '\\n'
    MDOM::Token::Whitespace    '\t '
    MDOM::Token::Bare          '@b'
    MDOM::Token::Whitespace    '   '
    MDOM::Token::Bare          '@c'
    MDOM::Token::Whitespace    '\n'
  MDOM::Token::Whitespace      '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare          '@b'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace    '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare         '@c'
    MDOM::Token::Separator    ':'
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Bare         ';'
      MDOM::Token::Whitespace    '\n'



=== TEST 8: line continuations in prereq list
--- src

a: \
	b\
    c \
    d

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Continuation    '\\n'
    MDOM::Token::Whitespace    '\t'
    MDOM::Token::Bare    'b'
    MDOM::Token::Continuation    '\\n'
    MDOM::Token::Whitespace    '    '
    MDOM::Token::Bare    'c'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Continuation    '\\n'
    MDOM::Token::Whitespace    '    '
    MDOM::Token::Bare    'd'
    MDOM::Token::Whitespace    '\n'



=== TEST 9: line continuations in prereqs and "inline" commands
--- src

a: \
	b;\
    c \
    d

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Continuation    '\\n'
    MDOM::Token::Whitespace    '\t'
    MDOM::Token::Bare          'b'
    MDOM::Command
      MDOM::Token::Separator   ';'
      MDOM::Token::Bare    '\\n    c \\n    d'
      MDOM::Token::Whitespace    '\n'



=== TEST 10: $@, $a, etc.
--- src
all: $a $(a) ${c}
	echo $@ $a ${a} ${abc} ${}
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Interpolation    '$a'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Interpolation    '$(a)'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Interpolation    '${c}'
    MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Bare    'echo '
    MDOM::Token::Interpolation    '$@'
    MDOM::Token::Bare    ' '
    MDOM::Token::Interpolation    '$a'
    MDOM::Token::Interpolation    '${a}'
    MDOM::Token::Interpolation    '${abc}'
    MDOM::Token::Interpolation    '${}'
    MDOM::Token::Whitespace    '\n'



=== TEST 11: basic variable setting
--- src
all: ; echo \$a
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace    ' '
      MDOM::Token::Bare          'echo \'
      MDOM::Token::Interpolation '$a'
      MDOM::Token::Whitespace    '\n'



=== TEST 12: unescaped '#'
--- src
all: foo\\# hello
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    'foo\\'
    MDOM::Token::Comment    '# hello'
    MDOM::Token::Whitespace    '\n'



=== TEST 13: when no space between words and '#'
--- src
\#a: foo#hello
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare    '\#a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    'foo'
    MDOM::Token::Comment    '#hello'
    MDOM::Token::Whitespace    '\n'



=== TEST 14: standalone single-line comment
--- src
# hello
#world!
--- dom
MDOM::Document::Gmake
  MDOM::Token::Comment    '# hello'
  MDOM::Token::Whitespace '\n'
  MDOM::Token::Comment    '#world!'
  MDOM::Token::Whitespace '\n'



=== TEST 15: standalone multi-line comment
--- src
# hello \
	world\
    !
--- dom
MDOM::Document::Gmake
  MDOM::Token::Comment    '# hello \\n\tworld\\n    !'
  MDOM::Token::Whitespace '\n'



=== TEST 16: comments indented by a tab
--- src
	# blah
--- dom
MDOM::Document::Gmake
  MDOM::Token::Whitespace    '\t'
  MDOM::Token::Comment       '# blah'
  MDOM::Token::Whitespace    '\n'



=== TEST 17: multi-line comment indented with tabs
--- src
	# blah \
hello!\
	# hehe
--- dom
MDOM::Document::Gmake
  MDOM::Token::Whitespace    '\t'
  MDOM::Token::Comment       '# blah \\nhello!\\n\t# hehe'
  MDOM::Token::Whitespace    '\n'



=== TEST 18: static pattern rules with ";" command
--- src

foo.o bar.o: %.o: %.c ; echo blah

%.c: ; echo $@

--- dom
MDOM::Document::Gmake
  MDOM::Rule::StaticPattern
    MDOM::Token::Bare    'foo.o'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    'bar.o'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    '%.o'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare    '%.c'
    MDOM::Token::Whitespace    ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace    ' '
      MDOM::Token::Bare    'echo blah'
      MDOM::Token::Whitespace    '\n'
  MDOM::Token::Whitespace    '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare    '%.c'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace    ' '
      MDOM::Token::Bare    'echo '
      MDOM::Token::Interpolation    '$@'
      MDOM::Token::Whitespace    '\n'

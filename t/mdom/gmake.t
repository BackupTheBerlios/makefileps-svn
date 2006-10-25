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
    $got =~ s/[ \t]+(?=\')/    /gs;
    $expected =~ s/[ \t]+(?=\')/    /gs;
    is $got, $expected, "$name - DOM structure ok";
    warn $dumper->string if $name =~ /TEST 0/;
};

__DATA__

=== TEST 0:
--- src

all: ; echo "hello, world"

--- dom



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
    MDOM::Token::Bare         'echo'
    MDOM::Token::Whitespace   ' '
    MDOM::Token::Bare         '"hello,'
    MDOM::Token::Whitespace   ' '
    MDOM::Token::Bare         'world"'
    MDOM::Token::Whitespace   '\n'

#: Makefile-Parser.t
#: Test script for Makefile/Parser.pm
#: v0.12
#: Copyright (c) 2005 Agent Zhang
#: 2005-09-24 2006-02-02

use strict;
use warnings;
use Cwd;
use FindBin;

my $dir = $FindBin::Bin;

use Test::More tests => 157;
use Makefile::Parser;

#$Makefile::Parser::Debug = 0;
$Makefile::Parser::Strict = 1;
my $pack = 'Makefile::Parser';

my $mk = $pack->new;
ok $mk, 'object defined';
isa_ok $mk, 'Makefile::Parser';
ok $mk->parse_file("$dir/Makefile");
is $mk->{_file}, "$dir/Makefile";
can_ok $mk, 'error';
ok !defined $pack->error;

is $mk->var('FOO'), "\\";
is $mk->var('FOO2'), "a b \\";
is $mk->var('IDU_LIB'), "inc\\Idu.pm";
is $mk->var('DISASM_LIB'), "inc\\Disasm.pm";
is $mk->var('CIDU_DLL'), "C\\idu.dll";
is $mk->var('CIDU_LIB'), "C\\idu.lib";
is $mk->var('RAW_AST'), "encoding.ast";
is $mk->var('GLOB_AST'), "..\\Config.ast";
is $mk->var('STAT_AST'), "state_mac.ast";
is $mk->var('PAT_AST'), "pat_tree.ast";
is $mk->var('CIDU_TT'), "C\\idu.c.tt";
is $mk->var('RM_F'), "perl -MExtUtils::Command -e rm_f";
is $mk->var('PAT_COVER_FILES'), "t\\pat_cover.ast.t t\\pat_cover.t";
is $mk->var('MIN_T_FILES'), join(' ', qw/t\\pat_cover.ast.t t\\pat_cover.t
    t\optest.t t\my_perl.exe.t t\types.cod.t
	t\catln.t t\exe2hex.t t\hex2bin.t t\bin2hex.t t\bin2asm.t t\ndisasmi.t
	t\Idu.t t\pat_tree.t t\state_mac.t t\Idu-Util.t t\cidu.t
	t\opname.t t\error.t t\operand.t t\01disasm.t t\02disasm.t t\03disasm.t
	t\disasm_cover.t t\ndisasm.t/);
is $mk->var('C_PAT_COVER_FILES'), "t\\cpat_cover.ast.t t\\cpat_cover.t";
is $mk->var('C_MIN_T_FILES'), join(' ', qw/t\\cpat_cover.ast.t t\\cpat_cover.t
    t\cmy_perl.exe.t t\ctypes.cod.t
	t\cidu.t t\copname.t t\cerror.t t\coperand.t/);
is $mk->var('EXE'), "hex2bin.exe";
is $mk->var('COD'), "main.cod";

is scalar($mk->vars), 23;
my @tars = $mk->targets;
is scalar(@tars), 82;
isa_ok $tars[0], 'Makefile::Target';

my @roots = $mk->roots;
is join(' ', sort @roots), 'clean cmintest ctest doc foo foo2 mintest smoke test';

my $tar = $mk->target('all');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'all';
my @deps = qw/inc\\Idu.pm hex2bin.exe bin2hex.exe t_dir C\\idu.dll C\\idu.lib
              C\idui.exe inc\\Disasm.pm/;
my @prereqs = $tar->prereqs;
is scalar(@prereqs), scalar(@deps);
is join(' ', @prereqs), join(' ', @deps);
is join("\n", $tar->commands), '';
is $tar->colon_type, '::';

my $tar2 = $mk->target;
is $tar, $tar2;

$tar = $mk->target($mk->var('IDU_LIB'));
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, $mk->var('IDU_LIB');
@deps = ($mk->var('IDU_TT'), $mk->var('GLOB_AST'), $mk->var('STAT_AST'));
@prereqs = $tar->prereqs;
is scalar(@prereqs), scalar(@deps);
is join(' ', @prereqs), join(' ', @deps);
is join("\n", $tar->commands), 'astt -o inc\Idu.pm -t ' . join(' ', @deps);
is $tar->colon_type, ':';

$tar = $mk->target('foo');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'foo';
@prereqs = $tar->prereqs;
is scalar(@prereqs), 3;
is join(' ', @prereqs), "a b \\";
is $tar->colon_type, ':';

$tar = $mk->target('foo2');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'foo2';
is $tar, 'foo2';
@prereqs = $tar->prereqs;
is scalar(@prereqs), 5;
is join(' ', @prereqs), "a b c d \\";
is $tar->colon_type, ':';

$tar = $mk->target('t_dir');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 't_dir';
@prereqs = $tar->prereqs;
is scalar(@prereqs), 0;
is join("\n", $tar->commands), "cd t\n\$(MAKE) /nologo\ncd..";
is $tar->colon_type, ':';

$tar = $mk->target('run_test');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'run_test';
@prereqs = $tar->prereqs;
is scalar(@prereqs), 0;
my $var = $mk->var('T_FILES');
is join("\n", $tar->commands)."\n", <<"_EOC_";
set HARNESS_OK_SLOW = 1
perl -MExtUtils::Command::MM -e "\@ARGV = map glob, \@ARGV; test_harness(0, '.', '.');" $var
_EOC_
is $tar->colon_type, ':';

$tar = $mk->target('t\cpat_cover.ast.t');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 't\cpat_cover.ast.t';
@deps = qw(coptest.tt t\pat_cover.ast.ast);
@prereqs = $tar->prereqs;
is scalar(@prereqs), scalar(@deps);
is join(' ', @prereqs), join(' ', @deps);
is join("\n", $tar->commands)."\n", <<'_EOC_';
echo $ast = { 'ast_file', 't/pat_cover.ast.ast' }; > t\tmp
astt -o t\cpat_cover.ast.t -t coptest.tt t\tmp t\pat_cover.ast.ast
del t\tmp
_EOC_
is $tar->colon_type, ':';

ok !defined($mk->parse_file('Makefile.bar.bar')), 'object not defined';
like(Makefile::Parser->error, qr/Cannot open Makefile.bar.bar for reading:.*/);

ok !$mk->parse_file('Makefile.bar.bar');
ok defined $mk, 'object defined';
like(Makefile::Parser->error, qr/Cannot open Makefile.bar.bar for reading:.*/);

my $saved_dir = Cwd::cwd;
chdir($dir);
$mk = $pack->new;
$mk->parse_file;
$tar = $mk->target('test');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'test';
is $mk->{_file}, "Makefile";

$mk = $pack->new;
$mk->parse_file;
$tar = $mk->target;
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'all';
is $mk->{_file}, "Makefile";

$mk = $pack->new;
$mk->parse_file;
$var = $mk->var('IDU_LIB');
ok $var;
is $var, 'inc\\Idu.pm';
is $mk->{_file}, "Makefile";

$mk = $pack->new;
$mk->parse_file;
my @vars = $mk->vars;
ok @vars > 5;
ok $vars[0];
is $mk->{_file}, "Makefile";

$mk = $pack->new;
$mk->parse_file;
@tars = $mk->targets;
ok @tars > 5;
isa_ok $tars[0], 'Makefile::Target';
is $mk->{_file}, "Makefile";

$mk = $pack->new;
$mk->parse_file;
@tars = $mk->roots;
ok @tars > 5;
is join(' ', sort @tars),
    'clean cmintest ctest doc foo foo2 mintest smoke test';
#is $tars[0], 'all';
is $mk->{_file}, "Makefile";

my $mk2 = $mk->new;
$mk2->parse_file;
isa_ok $mk, 'Makefile::Parser';

chdir $saved_dir;

#####
# Makefile2
####

#warn "!!! Makefile2 !!!\n";
my $ps = Makefile::Parser->new;
$ps->parse_file("$dir/Makefile2");

@roots = $ps->roots;
is join(' ', sort @roots), 'all clean';

$tar = $ps->target('sum2.exe');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.exe';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.obj';

$tar = $ps->target('sum2.obj');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.obj';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.asm';

$tar = $ps->target('ast++.sum.o');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'ast++.sum.o';
my @cmds = $tar->commands;
is join("\n", @cmds), 'cl /L ast++.sum.lib ast++.sum.c > ast++.sum.o';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'ast++.sum.c';

@tars = $ps->targets;
is join(' ', sort @tars), 'all ast++.sum.o clean sum1.exe sum1.obj sum2.exe sum2.obj';

####
# Makefile3
####

#warn "!!! Makefile3 !!!\n";
ok $ps->parse_file("$dir/Makefile3");

@roots = $ps->roots;
is join(' ', sort @roots), 'all clean';

$tar = $ps->target('sum2.exe');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.exe';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.obj';

$tar = $ps->target('sum2.obj');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.obj';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.asm';

$tar = $ps->target('ast++.sum.o');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'ast++.sum.o';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'ast++.sum.c';

@tars = $ps->targets;
is join(' ', sort @tars), 'all ast++.sum.o clean sum1.exe sum1.obj sum2.exe sum2.obj';

#####
# Makefile4
####

#warn "!!! Mafefile4 !!!\n";

$ps->parse_file("$dir/Makefile4");

@roots = $ps->roots;
is join(' ', sort @roots), 'all clean';

$tar = $ps->target('sum2.exe');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.exe';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.obj';

$tar = $ps->target('sum2.obj');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'sum2.obj';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'sum2.asm';

$tar = $ps->target('ast++.sum.o');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'ast++.sum.o';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'ast++.sum.c';

@tars = $ps->targets;
is join(' ', sort @tars), 'all ast++.sum.o clean sum1.exe sum1.obj sum2.exe sum2.obj';

#warn "!!! Makefile5 !!!\n";
ok $ps->parse_file("$dir/Makefile5");

@roots = $ps->roots;
is join(' ', sort @roots), 'abc';

$tar = $ps->target('abc');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'abc';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), 'foo.obj';
is join("\n", $tar->commands), 'link 5 5 $(MAKE) $(CC)  > abc';

$tar = $ps->target('foo.obj');
ok $tar;
isa_ok $tar, 'Makefile::Target';
is $tar->name, 'foo.obj';
@prereqs = $tar->prereqs;
is join(' ', @prereqs), '';
is join("\n", $tar->commands), 'echo foo.obj';

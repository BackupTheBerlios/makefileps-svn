#: escape.t
#:
#: Description:
#:   Test various types of escaping in makefiles.
#: Details:
#:   Make sure that escaping of `:' works in target names.
#:   Make sure escaping of whitespace works in target names.
#:   Make sure that escaping of '#' works.
#:
#: 2006-01-31 2006-02-02

use t::Backend::Gnu;

plan tests => 3 * blocks;

filters {
    source     => [qw< quote eval >],
};

# renamed $(path) to $(path2) since `path' is an essential env on Win32
our $source = <<'_EOC_';
$(path2)foo : ; @echo cp $^ $@

foo\ bar: ; @echo 'touch "$@"'

sharp: foo\#bar.ext
foo\#bar.ext: ; @echo foo\#bar.ext = '$@'
_EOC_

run { run_test_make $_[0]; }

__DATA__

=== TEST 1
empty `$^' trimmied
--- source:               $::source
--- stdout
cp foo
--- stderr
--- error_code
0



=== TEST 2: This one should fail, since the ":" is unquoted.
--- source:               $::source
--- options:              path2=p:
--- filename:             Makefile
--- stdout
--- stderr
Makefile:1: *** target pattern contains no `%'.  Stop.
--- error_code
512



=== TEST 3: This one should work, since we escape the ":".
--- source:               $::source
--- options:              'path2=p\:'
--- filename:             Makefile
--- stdout
cp p:foo
--- stderr
--- error_code
0



=== TEST 4: This one should fail, since the escape char is escaped.
--- source:               $::source
--- options:              'path2=p\\:'
--- filename:             Makefile
--- stdout
--- stderr
Makefile:1: *** target pattern contains no `%'.  Stop.
--- error_code
512



=== TEST 5: This one should work
--- source:               $::source
--- goals:                'foo bar'
--- stderr
--- stdout
touch "foo bar"
--- error_code
0



=== TEST 6: Test escaped comments
--- source:               $::source
--- goals:                sharp
--- stdout
foo#bar.ext = foo#bar.ext
--- stderr
--- error_code
0

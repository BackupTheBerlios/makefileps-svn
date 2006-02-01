package t::Parser::Gnu;

use t::Parser -Base;
use FindBin;

set_make   'GNU_MAKE_PATH', 'make';
util_path  '../../../script';
no_diff();

1;

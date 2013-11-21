BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
};

use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok('Translator');

subtest file_schema_returns_path => sub {
    my $translator = Translator->new();
    my $url = new URI::URL 'file:///foo/bar/baz';
    is($translator->_resolve_url($url),
        '/foo/bar/baz', 'file:///* returns /*');
};

done_testing;

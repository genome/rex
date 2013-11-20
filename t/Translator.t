use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use URI::URL qw();

use_ok('Translator');


subtest empty_schema_dies => sub {
    my $translator = Translator->new();
    my $url = new URI::URL '/foo/bar/baz';
    dies_ok {$translator->_resolve_url($url)} 'dies with empty schema';
};

subtest unknown_schema_dies => sub {
    my $translator = Translator->new();
    my $url = new URI::URL 'unknown:///foo/bar/baz';
    dies_ok {$translator->_resolve_url($url)} 'dies with unknown schema';
};

subtest file_schema_returns_path => sub {
    my $translator = Translator->new();
    my $url = new URI::URL 'file:///foo/bar/baz';
    is($translator->_resolve_url($url),
        '/foo/bar/baz', 'file:///* returns /*');
};


done_testing;

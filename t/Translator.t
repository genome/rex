use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use_ok('Translator');


subtest unknown_schema_dies => sub {
    my $translator = Translator->new();
    dies_ok {$translator->resolve_scalar_or_url('unknown:///foo')}
        'dies with unknown schema';

    lives_ok {$translator->resolve_scalar_or_url(':///foo')}
        'lives with empty schema';
};

subtest various_scalars_are_resolved => sub {
    my $translator = Translator->new();
    is($translator->resolve_scalar_or_url('some string'), 'some string',
        'simple string');
    is($translator->resolve_scalar_or_url('/foo/bar/baz'), '/foo/bar/baz',
        'path-like string');
    is($translator->resolve_scalar_or_url(':///foo/bar/baz'), ':///foo/bar/baz',
        'url-like string');
    is($translator->resolve_scalar_or_url(' :///foo'),' :///foo',
        'another url-like string');
    is($translator->resolve_scalar_or_url(5), 5, 'integer');
    is($translator->resolve_scalar_or_url(4.4), 4.4, 'float');
};


done_testing;

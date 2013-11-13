use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;


use_ok('Result');


subtest calculate_lookup_hash => sub {
    is(Result::calculate_lookup_hash({}),
        '99914b932bd37a50b983c5e7c90ae93b', 'empty case ok');
    is(Result::calculate_lookup_hash({'foo' => 'bar'}),
        '9bb58f26192e4ba00f01e2e7b136bbd8', 'simple case ok');

    is(Result::calculate_lookup_hash({'foo' => 'bar', 'baz' => 'buz'}),
        Result::calculate_lookup_hash({'baz' => 'buz', 'foo' => 'bar'}),
        "order doesn't matter");
};


done_testing;

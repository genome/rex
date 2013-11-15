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

subtest lookup_without_test_name => sub {
    my $lookup_hash = Result::calculate_lookup_hash({});
    my $tool_class_name = 'TestToolWithoutTestName';

    my $checkpoint = Result->create(
        lookup_hash => $lookup_hash,
        tool_class_name => $tool_class_name,
    );

    is(Result->lookup(inputs => {}, tool_class_name => $tool_class_name),
        $checkpoint, 'successful lookup');
    is(Result->lookup(inputs => {}, tool_class_name => $tool_class_name,
            test_name => 'some test name'),
        undef, "didn't find item with test name");
};

subtest lookup_with_test_name => sub {
    my $lookup_hash = Result::calculate_lookup_hash({});
    my $tool_class_name = 'TestToolWithTestName';
    my $test_name = 'some test name';

    my $checkpoint = Result->create(
        lookup_hash => $lookup_hash,
        tool_class_name => $tool_class_name,
        test_name => $test_name,
    );

    is(Result->lookup(inputs => {}, tool_class_name => $tool_class_name,
            test_name => $test_name),
        $checkpoint, "found item with test name");
    is(Result->lookup(inputs => {}, tool_class_name => $tool_class_name),
        undef, "didn't find item without test name");
};


done_testing;

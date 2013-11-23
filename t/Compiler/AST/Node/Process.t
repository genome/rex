use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use_ok('Compiler::AST::Node::Process');
use_ok('Compiler::AST::Node::Tool');
use_ok('Compiler::AST::Coupler::Constant');

subtest 'calculate_constants' => sub {
    my $coupler = Compiler::AST::Coupler::Constant->new(
        name => 'input_1',
        value => 77,
    );
    my $tool = Compiler::AST::Node::Tool->new(
        source_path => 'TestTool::Example',
        couplers => [$coupler],
    );
    my $process = Compiler::AST::Node::Process->new(
        source_path => 'something',
        nodes => [$tool],
    );
    is_deeply($process->constants, {'Example.input_1' => 77}, 'found inherited constant correctly');
};

subtest 'nested_constants' => sub {
    my $tool_coupler = Compiler::AST::Coupler::Constant->new(
        name => 'input_1',
        value => 77,
    );
    my $tool = Compiler::AST::Node::Tool->new(
        source_path => 'TestTool::Example',
        couplers => [$tool_coupler],
    );

    my $process_coupler = Compiler::AST::Coupler::Constant->new(
        name => 'Example.input_2',
        value => 88,
    );
    my $inside_process = Compiler::AST::Node::Process->new(
        source_path => 'Inside',
        couplers => [$process_coupler],
        nodes => [$tool],
    );

    # FIXME this line should go away after I impliment automatic link resolution.
    $inside_process->_add_input(name => 'Example.input_2', type => ($tool->input_named('input_2'))->type);

    my $outside_process = Compiler::AST::Node::Process->new(
        source_path => 'Outside',
        nodes => [$inside_process],
    );
    is_deeply($outside_process->constants, {
            'Inside.Example.input_1' => 77,
            'Inside.Example.input_2' => 88,
        }, 'found inherited and specified constants correctly');
};

done_testing;

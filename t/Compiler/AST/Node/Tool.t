use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use_ok('Compiler::AST::Node::Tool');
use_ok('Compiler::AST::Coupler::Constant');

subtest outputs => sub {
    my $tool = Compiler::AST::Node::Tool->new(
        source_path => 'TestTool::Example',
    );
    is($tool->unique_output(['Beta'])->name, 'output_3', 'found unique output');
    dies_ok {$tool->unique_output(['Alpha']);} 'more than one output dies';
    dies_ok {$tool->unique_output(['bad']);} 'unknown type dies';
};

subtest inputs => sub {
    my $tool = Compiler::AST::Node::Tool->new(
        source_path => 'TestTool::Example',
    );
    is_deeply($tool->inputs->{input_1}->tags, ['Alpha'], 'found input by name');
};

subtest constants => sub {
    my @couplers;
    push @couplers, Compiler::AST::Coupler::Constant->new(
        name => 'input_1',
        value => 77,
    );
    push @couplers, Compiler::AST::Coupler::Constant->new(
        name => 'input_2',
        value => 88,
    );
    my $tool = Compiler::AST::Node::Tool->new(
        source_path => 'TestTool::Example',
        couplers => \@couplers,
    );
    is_deeply($tool->constants, {'input_1' => 77, 'input_2' => 88}, 'found constants');
};

done_testing;

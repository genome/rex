package Compiler::AST::Definition::Tool;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use Genome::WorkflowBuilder::Command;
use Memoize;


class Compiler::AST::Definition::Tool {
    is => 'Compiler::AST::Definition',

    has => [
        command => {
            is => 'Text',
        },

        inputs => {
            is => 'Compiler::AST::Input',
            is_many => 1,
        },
        outputs => {
            is => 'Compiler::AST::Output',
            is_many => 1,
        },
    ],
};


sub workflow_builder {
    my ($self, $alias) = @_;
    return Genome::WorkflowBuilder::Command->create(
        name => $alias, command => $self->command);
}
Memoize::memoize('workflow_builder');

sub constants {
    return {};
}

1;

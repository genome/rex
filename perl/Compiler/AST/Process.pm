package Compiler::AST::Process;

use strict;
use warnings FATAL => 'all';

use UR;

use Compiler::AST::Node;


class Compiler::AST::Process {
    is => 'Compiler::AST::Node',

    has => [
        children => {
            is => 'Compiler::AST::Node',
            is_many => 1,
        },
    ],
};


sub inputs {
    my $self = shift;

    my @results;
    for my $child ($self->children) {
        push @results, $child->inputs;
    }

    return @results;
}


sub outputs {
    my $self = shift;

    my @results;
    for my $child ($self->children) {
        push @results, $child->outputs;
    }

    return @results;
}


1;

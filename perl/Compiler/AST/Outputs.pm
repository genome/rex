package Compiler::AST::Outputs;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Outputs {
    has => [
        entries => {
            is => 'Compiler::AST::Output',
            is_many => 1,
        },
    ],
};


1;


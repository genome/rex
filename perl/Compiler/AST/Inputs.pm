package Compiler::AST::Inputs;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Inputs {
    has => [
        entries => {
            is => 'Compiler::AST::Input',
            is_many => 1,
        },
    ],
};


1;

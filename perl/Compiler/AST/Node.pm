package Compiler::AST::Node;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Node {
    is_abstract => 1,

    id_generator => '-uuid',

    has => [
        operation_type => {
            is => 'Text',
        },
    ],
};


sub inputs {
}

sub outputs {
}


1;

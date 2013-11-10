package Compiler::AST::Link::Internal;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Link::Internal {
    is => 'Compiler::AST::Link',

    has => [
        source => {
            is => 'Text',
        },
    ],
};


sub is_internal { return 1; }
sub is_input { return 0; }
sub is_output { return 0; }


1;

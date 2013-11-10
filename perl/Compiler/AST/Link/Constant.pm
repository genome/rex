package Compiler::AST::Link::Constant;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Link::Constant {
    is => 'Compiler::AST::Link',

    has => [
        value => {
            is => 'Text',
        },
    ],
};

sub is_internal { return 0; }
sub is_input { return 1; }
sub is_output { return 0; }


1;

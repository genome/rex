package Compiler::AST::IO;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::IO {
    id_generator => '-uuid',

    has => [
        name => {
            is => 'Text',
        },
        type => {
            is => 'Text',
        },
    ],
};


1;

package Compiler::AST::IOEntry;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::IOEntry {
    id_generator => '-uuid',

    has => [
        name => {
            is => 'Text',
        },
        data_type => {
            is => 'Text',
        },
    ],
};


1;

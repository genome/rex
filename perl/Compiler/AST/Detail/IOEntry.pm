package Compiler::AST::Detail::IOEntry;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::Detail::IOEntry {
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

package Compiler::AST::IOEntry;

use strict;
use warnings FATAL => 'all';

use UR;


class Compiler::AST::IOEntry {
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

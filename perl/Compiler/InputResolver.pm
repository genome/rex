package Compiler::InputResolver;

use strict;
use warnings 'FATAL' => 'all';

use UR;

class Compiler::InputResolver {
    has => {
        parse_tree => {
            is => 'HASH',
        },
    },
};


sub input_tree {
    my $self = shift;
}


1;

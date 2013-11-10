package Compiler::AST::Link;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);


class Compiler::AST::Link {
    id_generator => '-uuid',
    is_abstract => 1,

    has => [
        property_name => {
            is => 'Text',
        },
    ],
};


sub is_internal { confess 'Abstract method'; }
sub is_input { confess 'Abstract method'; }
sub is_output { confess 'Abstract method'; }

1;

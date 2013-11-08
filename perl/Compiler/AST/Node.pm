package Compiler::AST::Node;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);


class Compiler::AST::Node {
    is_abstract => 1,

    id_generator => '-uuid',

    has => [
        operation_type => {
            is => 'Text',
        },
        explicit_link_info => {
            is => 'HASH',
            is_optional => 1,
        },
    ],
};


sub name {
    my $self = shift;
    return $self->operation_type;
}

sub inputs { confess "Abstract method"; }
sub outputs { confess "Abstract method"; }
sub workflow_builder { confess "Abstract method"; }


1;

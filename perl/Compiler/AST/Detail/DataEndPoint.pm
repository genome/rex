package Compiler::AST::Detail::DataEndPoint;

use strict;
#use warnings FATAL => 'all';

use UR;


class Compiler::AST::Detail::DataEndPoint {
    id_by => ['node_id', 'property_name'],

    has => [
        node => {
            is => 'Compiler::AST::Node',
            id_by => 'node_id',
        },

        node_id => {
            is => 'Text',
        },

        property_name => {
            is => 'Text',
        },
    ],
};

sub create {
    my $class = shift;

    my $self = $class->get(@_);

    unless (defined($self)) {
        $self = $class->SUPER::create(@_);
    }

    return $self;
}


sub workflow_builder {
    my $self = shift;
    return $self->node->workflow_builder;
}

sub alias {
    my $self = shift;
    return $self->node->alias;
}


1;

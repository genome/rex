package Compiler::AST::Tool;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use Compiler::AST::Node;
use Compiler::AST::IOEntry;


class Compiler::AST::Tool {
    is => 'Compiler::AST::Node',
    has => [
        input_entry => {
            is => 'Compiler::AST::IOEntry',
            is_many => 1,
        },
    ],
};


sub inputs {
    my $self = shift;

    my %result;
    for my $entry ($self->input_entry) {
        if (exists $result{$entry->name}) {
            confess sprintf(
                "Repeated input name (%s) in Tool definition %s",
                $entry->name, $self->operation_type);
        }

        $result{$entry->name} = $entry->data_type;
    }

    return \%result;
}

sub outputs {
}


1;

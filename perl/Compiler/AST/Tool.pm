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
        output_entry => {
            is => 'Compiler::AST::IOEntry',
            is_many => 1,
        },
    ],
};


sub inputs {
    my $self = shift;

    return $self->_collect_by_name($self->input_entry);
}

sub outputs {
    my $self = shift;

    return $self->_collect_by_name($self->output_entry);
}


sub _collect_by_name {
    my $self = shift;

    my %result;
    for my $entry (@_) {
        if (exists $result{$entry->name}) {
            confess sprintf(
                "Repeated entry name (%s) in Tool definition %s",
                $entry->name, $self->operation_type);
        }

        $result{$entry->name} = $entry->data_type;
    }

    return \%result;
}


1;

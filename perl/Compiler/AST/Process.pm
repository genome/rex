package Compiler::AST::Process;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use Compiler::AST::Node;

use Genome::WorkflowBuilder::DAG;
use Genome::WorkflowBuilder::Link;


class Compiler::AST::Process {
    is => 'Compiler::AST::Node',

    has => [
        children => {
            is => 'Compiler::AST::Node',
            is_many => 1,
        },
    ],
};


sub inputs {
    my $self = shift;

    $self->_validate_unique_children;
    my $producers = $self->_get_producers;
    my $consumers = $self->_get_consumers;

    my %result;
    for my $data_type (keys %$consumers) {
        if (!$producers->{$data_type}) {
            $result{$self->_data_name($data_type)} = $data_type;
        }
    }

    return \%result;
}

sub outputs {
    my $self = shift;

    $self->_validate_unique_children;
    my $producers = $self->_get_producers;
    my $consumers = $self->_get_consumers;

    my %result;
    for my $data_type (keys %$producers) {
        if (!$consumers->{$data_type}) {
            $result{$self->_data_name($data_type)} = $data_type;
        }
    }

    return \%result;
}

sub workflow_builder {
    my $self = shift;

}


sub _validate_unique_children {
    my $self = shift;

    my %child_lookup;
    for my $child ($self->children) {
        if (exists $child_lookup{$child->name}) {
            confess sprintf(
                "Multiple children with same name (%s) in process %s",
                $child->name, $self->name);
        }
        $child_lookup{$child->name} = $child;
    }
}

sub _data_name {
    my ($self, $data_type) = @_;
    return sprintf("%s->%s", $self->id, $data_type);
}

sub _get_producers {
    my $self = shift;

    my %result;
    for my $child ($self->children) {
        my $child_outputs = $child->outputs;
        for my $name (keys %$child_outputs) {
            my $data_type = $child_outputs->{$name};
            push @{$result{$data_type}}, $child;
        }
    }
    return \%result;
}

sub _get_consumers {
    my $self = shift;

    my %result;
    for my $child ($self->children) {
        my $child_inputs = $child->inputs;
        for my $name (keys %$child_inputs) {
            my $data_type = $child_inputs->{$name};
            push @{$result{$data_type}}, $child;
        }
    }
    return \%result;
}


1;

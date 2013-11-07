package Compiler::AST::Process;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use Compiler::AST::Node;

use Genome::WorkflowBuilder::DAG;
use Genome::WorkflowBuilder::Link;
use Memoize;


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

    my $dag = Genome::WorkflowBuilder::DAG->create(name => $self->name);

    $self->_add_operations_to($dag);
    $self->_add_links_to($dag);

    return $dag;
}
Memoize::memoize('workflow_builder');


sub _validate_unique_children {
    my $self = shift;

    my %child_lookup;
    for my $child ($self->children) {
        if (exists $child_lookup{$child->alias}) {
            confess sprintf(
                "Multiple children with same alias (%s) in process %s",
                $child->alias, $self->alias);
        }
        $child_lookup{$child->alias} = $child;
    }
}

sub _data_name {
    my ($self, $data_type) = @_;
    return sprintf("%s:%s", "input", $data_type);
}

sub _get_producers {
    my $self = shift;

    my %result;
    for my $child ($self->children) {
        my $child_outputs = $child->outputs;
        for my $name (keys %$child_outputs) {
            my $data_type = $child_outputs->{$name};
            push @{$result{$data_type}}, {
                child => $child,
                property_name => $name};
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
            push @{$result{$data_type}}, {
                child => $child,
                property_name => $name};
        }
    }
    return \%result;
}


sub _add_operations_to {
    my ($self, $dag) = @_;

    for my $child ($self->children) {
        $dag->add_operation($child->workflow_builder);
    }
    return;
}

sub _add_links_to {
    my ($self, $dag) = @_;

    $self->_validate_unique_children;
    my $producers = $self->_get_producers;
    my $consumers = $self->_get_consumers;

    for my $data_type (keys %$consumers) {
        if (!$producers->{$data_type}) {
            for my $dest_spec (@{$consumers->{$data_type}}) {
                my $child = $dest_spec->{child};
                my $name = $dest_spec->{property_name};
                $dag->connect_input(
                    input_property => $self->_data_name($data_type),
                    destination => $child->workflow_builder,
                    destination_property => $name);
            }

        } elsif (scalar(@{$producers->{$data_type}}) == 1) {
            my $prod_child = $producers->{$data_type}[0]{child};
            my $prod_name = $producers->{$data_type}[0]{property_name};

            for my $dest_spec (@{$consumers->{$data_type}}) {
                my $dest_child = $dest_spec->{child};
                my $dest_name = $dest_spec->{property_name};

                $dag->create_link(
                    source => $prod_child->workflow_builder,
                    source_property => $prod_name,
                    destination => $dest_child->workflow_builder,
                    destination_property => $dest_name);
            }

        } else {
            confess sprintf("Found multiple producers for data type (%s) in %s",
                $data_type, $self->name);

        }
        delete $producers->{$data_type};
    }

    for my $data_type (keys %$producers) {
        if (scalar(@{$producers->{$data_type}}) == 1) {
            my $prod_child = $producers->{$data_type}[0]{child};
            my $prod_name = $producers->{$data_type}[0]{property_name};
            $dag->connect_output(
                source => $prod_child->workflow_builder,
                source_property => $prod_name,
                output_property => $self->_data_name($data_type),
            );
        } else {
            confess sprintf("Found multiple producers for data type (%s) in %s",
                $data_type, $self->name);
        }
    }

    return;
}


1;

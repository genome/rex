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
            is => 'HASH',
        },

        explicit_link_info => {
            is => 'HASH',
            is_optional => 1,
        },

        _child_reverse_lookup => {
            is => 'HASH',
            is_optional => 1,
            is_transient => 1,
        },
    ],
};


sub create {
    my $class = shift;
    my $self = $class->SUPER::create(@_);

    $self->_child_reverse_lookup({});
    for my $alias (keys %{$self->children}) {
        my $child = $self->children->{$alias};
        $self->_child_reverse_lookup->{$child->id} = $alias;
    }

    return $self;
}

sub inputs {
    my $self = shift;

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
    my ($self, $alias) = @_;

    my $dag = Genome::WorkflowBuilder::DAG->create(name => $alias);

    $self->_add_operations_to($dag);

    $self->_add_explicit_links_to($dag);
    $self->_add_implicit_links_to($dag);

    return $dag;
}
Memoize::memoize('workflow_builder');

sub _add_explicit_links_to {
    my ($self, $dag) = @_;

    my $links = $self->_generate_explicit_links;
    $self->_add_links_to($dag, $links);

    return;
}

sub _add_implicit_links_to {
    my ($self, $dag) = @_;

    my $links = $self->_generate_implicit_links();
    $self->_add_links_to($dag, $links);
}

sub _get_remaining_producers_and_consumers {
    my $self = shift;
    my $producers = $self->_get_producers;
    my $consumers = $self->_get_consumers;
    $self->_remove_explicitly_linked_producers_and_consumers(
        $producers, $consumers);

    return $producers, $consumers;
}

sub _remove_explicitly_linked_producers_and_consumers {
    my ($self, $producers, $consumers) = @_;

    for my $type (keys %{$self->explicit_link_info}) {
        # XXX For early testing
        next unless $type eq 'internal';

        my $type_hash = $self->explicit_link_info->{$type};

        for my $destination_alias (keys %$type_hash) {
            my $destination_hash = $type_hash->{$destination_alias};
            my $destination = $self->children->{$destination_alias};

            for my $property_name (keys %$destination_hash) {
                my $data_type = $destination->type_of($property_name);
                my $property_hash = $destination_hash->{$property_name};
                my $source = $self->children->{$property_hash->{alias}};

                for my $producer (@{$producers->{$data_type}}) {
                    if ($producer->{child}->id eq $source->id) {
                        $producer->{used} = 1;
                        last;
                    }
                }

                for my $consumer (@{$consumers->{$data_type}}) {
                    if ($consumer->{child}->id eq $destination->id
                        && $consumer->{property_name} eq $property_name) {
                        $consumer->{satisfied} = 1;
                        last;
                    }
                }
            }
        }
    }

    for my $data_type (keys %$producers) {
        $producers->{$data_type} = [
            grep {$_->{used} == 0} @{$producers->{$data_type}}];
    }

    for my $data_type (keys %$consumers) {
        $consumers->{$data_type} = [
            grep {$_->{satisfied} == 0} @{$consumers->{$data_type}}];
    }

    return;
}

sub _data_name {
    my ($self, $data_type) = @_;
    return sprintf("%s:%s", "input", $data_type);
}

sub _get_producers {
    my $self = shift;

    my %result;
    for my $child (values %{$self->children}) {
        my $child_outputs = $child->outputs;
        for my $name (keys %$child_outputs) {
            my $data_type = $child_outputs->{$name};
            push @{$result{$data_type}}, {
                child => $child,
                property_name => $name,
                used => 0,
            };
        }
    }
    return \%result;
}

sub _get_consumers {
    my $self = shift;

    my %result;
    for my $child (values %{$self->children}) {
        my $child_inputs = $child->inputs;
        for my $name (keys %$child_inputs) {
            my $data_type = $child_inputs->{$name};
            push @{$result{$data_type}}, {
                child => $child,
                property_name => $name,
                satisfied => 0,
            };
        }
    }
    return \%result;
}


sub _add_operations_to {
    my ($self, $dag) = @_;

    for my $child_alias (keys %{$self->children}) {
        my $child = $self->children->{$child_alias};
        $dag->add_operation($child->workflow_builder($child_alias));
    }
    return;
}

sub _generate_explicit_links {
    my $self = shift;

    my %links;
    for my $type (keys %{$self->explicit_link_info}) {
        my $type_hash = $self->explicit_link_info->{$type};

        for my $destination_alias (keys %$type_hash) {
            my $destination_hash = $type_hash->{$destination_alias};
            my $destination_child = $self->children->{$destination_alias};

            for my $property_name (keys %$destination_hash) {
                my $property_hash = $destination_hash->{$property_name};
                if ($property_hash->{type} eq 'link') {
                    my $source_child = $self->children->{
                        $property_hash->{alias}};

                    push @{$links{$type}}, {
                        source => $source_child->workflow_builder($property_hash->{alias}),
                        source_property => $source_child->unique_output_of_type(
                            $destination_child->type_of($property_name)),
                        destination => $destination_child->workflow_builder($destination_alias),
                        destination_property => $property_name,
                    };
                } elsif ($property_hash->{type} eq 'constant') {
                    my $destination_child = $self->children->{
                            $destination_alias};

                    push @{$links{$type}}, {
                        destination => $destination_child->workflow_builder($destination_alias),
                        destination_property => $property_name,
                        input_property => sprintf("%s.%s",
                            $destination_alias, $property_name),
                    },
                } else {
                    confess sprintf("Invalid property assignment type %s",
                        $property_hash->{type});
                }
            }
        }
    }

    return \%links;
}

sub _alias_of {
    my ($self, $child) = @_;

    return $self->_child_reverse_lookup->{$child->id};
}

sub _generate_implicit_links {
    my $self = shift;

    my ($producers, $consumers) = $self->_get_remaining_producers_and_consumers;
    my %links;
    for my $data_type (keys %$consumers) {
        if (!defined($producers->{$data_type})
            || scalar(@{$producers->{$data_type}}) == 0) {
            for my $dest_spec (@{$consumers->{$data_type}}) {
                my $child = $dest_spec->{child};
                my $name = $dest_spec->{property_name};
                push @{$links{'inputs'}}, {
                    input_property => $self->_data_name($data_type),
                    destination => $child->workflow_builder($self->_alias_of($child)),
                    destination_property => $name,
                };
            }

        } elsif (scalar(@{$producers->{$data_type}}) == 1) {
            my $prod_child = $producers->{$data_type}[0]{child};
            my $prod_name = $producers->{$data_type}[0]{property_name};

            for my $dest_spec (@{$consumers->{$data_type}}) {
                my $dest_child = $dest_spec->{child};
                my $dest_name = $dest_spec->{property_name};

                push @{$links{'internal'}}, {
                    source => $prod_child->workflow_builder($self->_alias_of($prod_child)),
                    source_property => $prod_name,
                    destination => $dest_child->workflow_builder($self->_alias_of($dest_child)),
                    destination_property => $dest_name,
                };
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
            push @{$links{'outputs'}}, {
                source => $prod_child->workflow_builder($self->_alias_of($prod_child)),
                source_property => $prod_name,
                output_property => $self->_data_name($data_type),
            };
        } else {
            confess sprintf("Found multiple producers for data type (%s) in %s",
                $data_type, $self->name);
        }
    }
    return \%links;
}

sub _add_links_to {
    my ($self, $dag, $links) = @_;


    for my $link (@{$links->{'inputs'}}) {
        $dag->connect_input(%{$link});
    }
    for my $link (@{$links->{'internal'}}) {
        $dag->create_link(%{$link});
    }
    for my $link (@{$links->{'outputs'}}) {
        $dag->connect_output(%{$link});
    }

    return;
}


1;

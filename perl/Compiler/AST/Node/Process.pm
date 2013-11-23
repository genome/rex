package Compiler::AST::Node::Process;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::MoreUtils qw(first_index);
use Params::Validate qw();
use Memoize;
use Genome;

use Compiler::AST::DataEndPoint;
use Compiler::AST::Node::Tool;
use Compiler::AST::Link;

extends 'Compiler::AST::Node';

has nodes => (
    is => 'ro',
    isa => 'ArrayRef[Compiler::AST::Node::Process|Compiler::AST::Node::Tool]',
    required => 1,
);
has links => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::Link]',
    default => sub {[]},
);
has producers => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[Compiler::AST::DataEndPoint]]',
    default => sub {{}},
);
has consumers => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[Compiler::AST::DataEndPoint]]',
    default => sub {{}},
);

sub BUILD {
    my $self = shift;

    $self->_set_missing_aliases;

    $self->_set_producers;
    $self->_set_consumers;

    $self->_set_constants;

    $self->_make_explicit_links;
    $self->_resolve_automatic_links;
    $self->_resolve_automatic_inputs;
    $self->_resolve_automatic_outputs;
    return;
}

sub dag {
    my $self = shift;

    my $dag = Genome::WorkflowBuilder::DAG->create(
        name => $self->alias,
    );

    for my $node (@{$self->nodes}) {
        $dag->add_operation($node->dag);
    }

    for my $link (@{$self->links}) {
        if ($link->source->node == $self) {
            $dag->connect_input(
                input_property => $link->source->name,
                destination => $link->destination->node->dag,
                destination_property => $link->destination->name,
            );
        } elsif ($link->destination->node == $self) {
            $dag->connect_output(
                output_property => $link->destination->name,
                source => $link->source->node->dag,
                source_property => $link->source->name,
            );
        } else {
            $dag->create_link(
                source => $link->source->node->dag,
                source_property => $link->source->name,
                destination => $link->destination->node->dag,
                destination_property => $link->destination->name,
            );
        }
    }
    return $dag;
}
Memoize::memoize('dag');

sub _set_producers {
    my $self = shift;

    for my $node (@{$self->nodes}) {
        for my $output (@{$node->outputs}) {
            my $bin = $self->producers->{$output->type};
            unless (defined $bin) {
                $bin = [];
                $self->producers->{$output->type} = $bin;
            }
            $output->is_used(0);
            push @$bin, $output;
        }
    }
    return;
}

sub _set_consumers {
    my $self = shift;

    for my $node (@{$self->nodes}) {
        for my $input (@{$node->inputs}) {
            my $bin = $self->consumers->{$input->type};
            unless (defined $bin) {
                $bin = [];
                $self->consumers->{$input->type} = $bin;
            }
            $input->is_used(0);
            push @$bin, $input;
        }
    }
    return;
}

sub _make_explicit_links {
    my $self = shift;

    my @links;
    for my $destination_node (@{$self->nodes}) {
        for my $coupler ($destination_node->internal_couplers) {
            my $destination_end_point = $destination_node->input_named($coupler->name);

            my $source_node = $self->_node_aliased($coupler->source_node_alias);
            my $source_end_point = $source_node->unique_output($destination_end_point->type);
            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}

sub _node_aliased {
    my $self = shift;
    my $alias = shift;

    for my $node (@{$self->nodes}) {
        return $node if $node->alias eq $alias;
    }
}

sub _link {
    my $self = shift;
    my %params = Params::Validate::validate(@_, {
        source => 1,
        destination => 1,
    });
    push @{$self->links}, Compiler::AST::Link->new(
        source => $params{source},
        destination => $params{destination},
    );

    ($params{source})->is_used(1);
    ($params{destination})->is_used(1);
}

sub _set_constants {
    my $self = shift;

    my %constants;
    for my $node (@{$self->nodes}) {
        my %node_constants = %{$node->constants};
        for my $name (keys %node_constants) {
            my $data_end_point = $node->input_named($name);
            my $local_name = $self->_automatic_property_name([$data_end_point]);
            my $value = $node_constants{$name};
            $constants{$local_name} = $value;

            # inherited constants should become inputs
            my $source = $self->_add_input(name => $local_name, type => $data_end_point->type);
            $self->_link(source => $source, destination => $data_end_point);
        }
    }

    # this may not be allowed by the compiler!
    # since name must start with lower_case, and the way we autogenerate input names
    # uses the tool/process source_path to start them, we cannot generate a valid
    # constant on a process. (We'll have a defaults file instead?)
    for my $coupler ($self->constant_couplers) {
        $constants{$coupler->name} = $coupler->value;
    }

    $self->constants(\%constants);
}

sub _add_input {
    my $self = shift;

    my $input = $self->_create_data_end_point(@_);
    push @{$self->inputs}, $input;
    return $input;
}

sub _resolve_automatic_links {
    my $self = shift;

    for my $type (keys %{$self->consumers}) {
        for my $consumer (@{$self->consumers->{$type}}) {
            next if $consumer->is_used;

            my $producers = $self->producers->{$type};
            next unless $producers;

            my @distinct_producers = grep {$_->node != $consumer->node} @$producers;
            if (scalar @distinct_producers == 1) {
                $self->_link(source => $distinct_producers[0], destination => $consumer);
            } elsif (scalar @distinct_producers > 1) {
                confess sprintf('Found multiple producers for type %s: %s',
                    $type, join(', ', map {$_->node->alias . '.' . $_->name} @distinct_producers),
                );
            }
        }
    }
}

sub _resolve_automatic_inputs {
    my $self = shift;

    for my $type (keys %{$self->consumers}) {
        my $consumers = $self->_unused_consumers($type);
        next unless scalar(@$consumers);

        my $source = $self->_add_input(
            name => $self->_automatic_property_name($consumers),
            type => $type,
        );
        for my $consumer (@$consumers) {
            $self->_link(source => $source, destination => $consumer);
        }
    }
}

sub _unused_consumers {
    my $self = shift;
    my $type = shift;

    my @result;
    for my $consumer (@{$self->consumers->{$type}}) {
        push @result, $consumer unless $consumer->is_used;
    }
    return \@result;
}

sub _resolve_automatic_outputs {
    my $self = shift;

    for my $type (keys %{$self->producers}) {
        my $producers = $self->_unused_producers($type);

        for my $producer (@$producers) {
            my $destination = $self->_add_output(
                name => $self->_automatic_property_name([$producer]),
                type => $type,
            );
            $self->_link(source => $producer, destination => $destination);
        }
    }
}

sub _unused_producers {
    my $self = shift;
    my $type = shift;

    my @result;
    for my $producer (@{$self->producers->{$type}}) {
        push @result, $producer unless $producer->is_used;
    }
    return \@result;
}

sub _add_output {
    my $self = shift;

    my $output = $self->_create_data_end_point(@_);
    push @{$self->outputs}, $output;
    return $output;
}

sub _set_missing_aliases {
    my $self = shift;

    my $tree = $self->_build_alias_tree;
    for my $node (@{$self->nodes}) {
        next if $node->alias;
        my @path = $node->source_path_components;
        my $res = _find_leaf($tree, @path);
        $node->alias($res);
    }

    return;
}


sub _build_alias_tree {
    my $self = shift;

    my $tree = {};
    for my $node (@{$self->nodes}) {
        next if $node->alias;
        _insert_path($tree, $node->source_path_components);
    }

    return $tree;
}

sub _insert_path {
    my ($tree, $path) = @_;

    my $next = shift @$path;
    if (@$path) {
        _insert_path($tree->{$next}, $path);
    } else {
        $tree->{$next} = {};
    }

    return;
}

sub _find_leaf {
    my ($tree, $path) = @_;

    my $node = $tree;
    my $current_part = shift @$path;
    my @result = ($current_part);

    while (scalar(keys %{$node->{$current_part}}) > 1) {
        $node = $node->{$current_part};
        $current_part = shift @$path;
        push @result, $current_part;
    }

    return join('::', reverse @result);
}


sub _automatic_property_name {
    my ($self, $data_end_points) = @_;

    if (scalar(@$data_end_points) > 1) {
        return sprintf("(%s)", join("+",
                map {$self->_automatic_property_name_component($_)}
                @$data_end_points));
    } elsif (scalar(@$data_end_points) == 1) {
        return $self->_automatic_property_name_component($data_end_points->[0]);
    } else {
        confess "Require at least one data end point to compute input name";
    }
}

sub _automatic_property_name_component {
    my ($self, $data_end_point) = @_;

    unless (defined($data_end_point)) {
        confess "Got undefined value for data_end_point";
    }

    return sprintf("%s.%s", $data_end_point->node->alias,
        $data_end_point->name);
}


1;

package Compiler::AST::Node::Process;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::MoreUtils qw(first_index);
use Params::Validate qw();
use Set::Scalar;
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
    isa => 'HashRef[ArrayRef[Set::Scalar]]',
    default => sub {{}},
);
has consumers => (
    is => 'rw',
    isa => 'HashRef[ArrayRef[Set::Scalar]]',
    default => sub {{}},
);
has flat_producers => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::DataEndPoint]',
    default => sub {[]},
);
has flat_consumers => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::DataEndPoint]',
    default => sub {[]},
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
        for my $output (values %{$node->outputs}) {
            push @{$self->flat_producers}, $output;
            for my $tag (@{$output->tags}) {
                my $bin = $self->producers->{$tag};
                unless (defined $bin) {
                    $bin = Set::Scalar->new;
                    $self->producers->{$tag} = $bin;
                }
                $output->is_used(0);
                $bin->insert($output);
            }
        }
    }
    return;
}

sub _set_consumers {
    my $self = shift;

    for my $node (@{$self->nodes}) {
        for my $input (values %{$node->inputs}) {
            push @{$self->flat_consumers}, $input;
            for my $tag (@{$input->tags}) {
                my $bin = $self->consumers->{$tag};
                unless (defined $bin) {
                    $bin = Set::Scalar->new;
                    $self->consumers->{$tag} = $bin;
                }
                $input->is_used(0);
                $bin->insert($input);
            }
        }
    }
    return;
}

sub _set_constants {
    my $self = shift;

    my %constants;
    for my $node (@{$self->nodes}) {
        my %node_constants = %{$node->constants};
        for my $name (keys %node_constants) {
            my $data_end_point = $node->inputs->{$name};
            my $local_name = $self->_automatic_property_name($data_end_point);
            my $value = $node_constants{$name};
            $constants{$local_name} = $value;

            # inherited constants should become inputs
            my $source = $self->_add_input(name => $local_name, tags => $data_end_point->tags);
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
    $self->inputs->{$input->name} = $input;
    return $input;
}


sub _make_explicit_links {
    my $self = shift;

    my @links;
    for my $destination_node (@{$self->nodes}) {
        for my $coupler ($destination_node->internal_couplers) {
            my $destination_end_point = $destination_node->inputs->{$coupler->name};

            my $source_node = $self->_node_aliased($coupler->source_node_alias);
            my $source_end_point = $source_node->unique_output($destination_end_point->tags);
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

sub _resolve_automatic_links {
    my $self = shift;

    CONSUMER: for my $consumer (@{$self->flat_consumers}) {
        next CONSUMER if $consumer->is_used;

        my @producer_set;
        for my $tag (@{$consumer->tags}) {
            my $producers = $self->producers->{$tag};
            next CONSUMER unless defined $producers; # automatic input
            push @producer_set, $producers;
        }

        my $potential_producers = _intersection(@producer_set);
        my $distinct_potential_producers = $potential_producers -
            Set::Scalar->new(values %{$consumer->node->outputs});

        if ($distinct_potential_producers->size == 1) {
            $self->_link(source => ($distinct_potential_producers->members)[0],
                destination => $consumer);
        } elsif ($distinct_potential_producers->size > 1) {
            confess sprintf('Found multiple producers for tags [%s]: %s while finding producer for %s.%s',
                join(', ', @{$consumer->tags}),
                join(', ', map {$_->node->alias . '.' . $_->name}
                    $distinct_potential_producers->members),
                $consumer->node->alias, $consumer->name
            );
        }
    }
    return;
}

sub _intersection {
    my ($first, @rest) = @_;

    return $first->intersection(@rest);
}

sub _resolve_automatic_inputs {
    my $self = shift;

    for my $consumer (@{$self->flat_consumers}) {
        next if $consumer->is_used;

        my $source = $self->_add_input(
            name => $self->_automatic_property_name($consumer),
            tags => $consumer->tags,
        );
        $self->_link(source => $source, destination => $consumer);
    }
    return;
}

sub _resolve_automatic_outputs {
    my $self = shift;

    for my $producer (@{$self->flat_producers}) {
        next if $producer->is_used;

        my $destination = $self->_add_output(
            name => $self->_automatic_property_name($producer),
            tags => $producer->tags,
        );
        $self->_link(source => $producer, destination => $destination);

    }
    return;
}

sub _add_output {
    my $self = shift;

    my $output = $self->_create_data_end_point(@_);
    $self->outputs->{$output->name} = $output;
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
    my ($self, $data_end_point) = @_;

    return sprintf("%s.%s", $data_end_point->node->alias,
        $data_end_point->name);
}


1;

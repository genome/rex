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

    $self->uuid("cluster_" . $self->_new_uuid);
    $self->_set_missing_aliases;

    $self->_set_producers;
    $self->_set_consumers;

    $self->_set_constants;

    $self->_make_explicit_inputs;
    $self->_make_explicit_outputs;
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

sub dot_nodes {
    my $self = shift;

    my @result;
    # input_connector
    push @result, sprintf('%s [label="@"];', $self->_new_uuid);

    for my $node (@{$self->nodes}) {
        push @result, @{$node->dot_nodes};
    }

    # output_connector
    push @result, sprintf('%s [label="@"];', $self->_new_uuid);

    return \@result;
}
Memoize::memoize('dot_nodes');

sub dot_links {
    my $self = shift;

    my @result;
    for my $node (@{$self->nodes}) {
        push @result, @{$node->dot_links};
    }

    for my $link (@{$self->links}) {
        my ($source_idx, $destination_idx) = (-1, 0);
        $source_idx = 0 if $link->source->node == $self;
        $destination_idx = -1 if $link->destination->node == $self;

        my $source_id = id_from_dot_node(
            @{$link->source->node->dot_nodes}[$source_idx]
        );
        my $destination_id = id_from_dot_node(
            @{$link->destination->node->dot_nodes}[$destination_idx]
        );
        push @result, sprintf('%s -> %s;', $source_id, $destination_id);
    }
    return \@result;
}

sub id_from_dot_node {
    my $dot_node = shift;
    return (split(/\s/, $dot_node))[0];
}

sub dot_cluster {
    my $self = shift;

    my @sub_clusters;
    for my $node (@{$self->nodes}) {
        push @sub_clusters, $node->dot_cluster if $node->dot_cluster;
    }

    my @node_ids;
    for my $dot_node (@{$self->dot_nodes}) {
        push @node_ids, id_from_dot_node($dot_node);
    }

    my $sub_clusters = join('; ', @sub_clusters) . ';' if @sub_clusters;
    my $node_ids = join('; ', @node_ids) . ';' if @node_ids;
    return sprintf('subgraph "cluster_%s" {label="%s"; %s %s}',
        $self->uuid,
        $self->alias,
        $sub_clusters || '',
        $node_ids || '',
    );
}

sub dot {
    my $self = shift;

    return sprintf("digraph G {\n%s\n%s\n%s\n}\n",
        join("\n", @{$self->dot_nodes}),
        join("\n", Set::Scalar->new(@{$self->dot_links})->members),
        join("\n", $self->dot_cluster),
    );
}

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
            my $source_end_point;
            if ($coupler->can('source_name')) {
                if ($source_node->outputs->{$coupler->source_name}) {
                    $source_end_point = $source_node->outputs->{$coupler->source_name};
                } else {
                    confess sprintf("No output named (%s) on node %s (%s)",
                        $coupler->source_name, $source_node->source_path, $source_node->alias);
                }
            } else {
                $source_end_point = $source_node->unique_output($destination_end_point->tags);
            }
            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}

sub _make_explicit_inputs {
    my $self = shift;

    my @links;
    for my $destination_node (@{$self->nodes}) {
        for my $coupler ($destination_node->input_couplers) {
            my $destination_end_point = $destination_node->inputs->{$coupler->name};

            my $source_end_point = $self->_find_or_add_input($coupler->input_name, $destination_end_point->tags);
            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}

sub _find_or_add_input {
    my ($self, $name, $tags) = @_;

    my $existing_input = $self->inputs->{$name};
    if (defined $existing_input) {
        $existing_input->update_tags($tags);
    } else {
        $existing_input = $self->_add_input(name => $name, tags => $tags);
    }
    return $existing_input;
}

sub _make_explicit_outputs {
    my $self = shift;

    my @links;
    for my $source_node (@{$self->nodes}) {
        for my $coupler ($source_node->output_couplers) {
            my $source_end_point = $source_node->outputs->{$coupler->name};

            my $destination_end_point = $self->_add_output(name => $coupler->output_name,
                tags => $source_end_point->tags);
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
    confess sprintf("No node found with alias (%s): [%s]",
        $alias, join(', ', map {sprintf("%s (%s)", $_->source_path, $_->alias)} @{$self->nodes}),
    );
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
    if (exists $self->outputs->{$output->name}) {
        confess sprintf("Tried to create output named (%s) that already exists on node %s (%s)",
            $output->name, $self->source_path, $self->alias);
    } else {
        $self->outputs->{$output->name} = $output;
    }
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

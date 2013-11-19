package Compiler::AST::Node;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use Memoize qw();

use Compiler::AST::Detail::DataEndPoint;


class Compiler::AST::Node {
    id_generator => '-uuid',

    has => [
        type => {
            is => 'Text',
        },

        alias => {
            is => 'Text',
            is_optional => 1,
        },

        parallel => {
            is => 'Text',
            is_many => 1,
            is_optional => 1,
        },

        explicit_links => {
            is => 'Compiler::AST::Link',
            is_many => 1,
            is_optional => 1,
        },
        explicit_constants => {
            is => 'Compiler::AST::Link::Constant',
            is_many => 1,
            is_optional => 1,
        },
    ],
};


sub definition {
    my $self = shift;

    require Compiler::Importer;
    return Compiler::Importer::import_file($self->type);
}
Memoize::memoize('definition');

sub workflow_builder {
    my $self = shift;

    return $self->definition->workflow_builder($self->alias);
}

sub inputs {
    my $self = shift;

    return $self->definition->inputs;
}

sub outputs {
    my $self = shift;

    return $self->definition->outputs;
}

sub constants {
    my $self = shift;

    return $self->definition->constants;
}

sub inputs_of {
    my ($self, $data_type) = @_;

    my @result;
    for my $input ($self->inputs) {
        if ($input->type eq $data_type) {
            push @result, Compiler::AST::Detail::DataEndPoint->create(
                node => $self, property_name => $input->name);
        }
    }

    return @result;
}
Memoize::memoize('inputs_of');

sub outputs_of {
    my ($self, $data_type) = @_;

    my @result;
    for my $output ($self->outputs) {
        if ($output->type eq $data_type) {
            push @result, Compiler::AST::Detail::DataEndPoint->create(
                node => $self, property_name => $output->name);
        }
    }

    return @result;
}
Memoize::memoize('outputs_of');

sub explicit_internal_links {
    my $self = shift;

    return grep {$_->is_internal} $self->explicit_links;
}

sub explicit_inputs {
    my $self = shift;

    return $self->explicit_constants;
}

sub unique_output_of_type {
    my ($self, $data_type) = @_;

    my @results = grep {$_->type eq $data_type} $self->outputs;
    unless (scalar(@results) == 1) {
        confess sprintf("Didn't find exactly 1 output with type %s on node %s",
            $data_type, $self->alias);
    }

    return $results[0]->name;
}

sub type_of {
    my ($self, $property_name) = @_;

    my @results = grep {$_->name eq $property_name}
        ($self->inputs, $self->outputs);
    unless (scalar(@results) == 1) {
        confess sprintf("Didn't find exactly 1 input/output property with the "
            . "name (%s) on node %s", $property_name, $self->alias);
    }

    return $results[0]->type;
}

sub type_path {
    my $self = shift;

    my @parts = split /::/, $self->type;
    my @reversed_parts = reverse @parts;
    return \@reversed_parts;
}


1;

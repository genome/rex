package Compiler::AST::Node;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);


class Compiler::AST::Node {
    is_abstract => 1,

    id_generator => '-uuid',

    has => [
        operation_type => {
            is => 'Text',
        },
    ],
};


sub name {
    my $self = shift;
    return $self->operation_type;
}

sub inputs { confess "Abstract method"; }
sub outputs { confess "Abstract method"; }
sub workflow_builder { confess "Abstract method"; }


sub type_of {
    my ($self, $property_name) = @_;

    my $input_result = $self->inputs->{$property_name};
    if (defined $input_result) {
        return $input_result;
    } else {
        my $output_result = $self->outputs->{$property_name};
        if (defined $output_result) {
            return $output_result;
        } else {
            confess sprintf("Could not find type for property %s",
                $property_name);
        }
    }
}

sub unique_output_of_type {
    my ($self, $type) = @_;

    my $outputs = $self->outputs;
    my $answer;
    for my $output_name (keys %$outputs) {
        if ($outputs->{$output_name} eq $type) {
            if (defined($answer)) {
                confess sprintf(
                    "Duplicate outputs found for type '%s': '%s' and '%s'",
                    $type, $answer, $output_name);
            } else {
                $answer = $output_name;
            }
        }
    }
    return $answer;
}


1;

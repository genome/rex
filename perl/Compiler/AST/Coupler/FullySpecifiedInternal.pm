package Compiler::AST::Coupler::FullySpecifiedInternal;

use Moose;
use warnings FATAL => 'all';

extends 'Compiler::AST::Coupler';

has fully_specified_source => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has source_node_alias => (
    is => 'rw',
    isa => 'Str',
);
has source_name => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;

    my ($source_node_alias, $source_name) = split(/\./, $self->fully_specified_source);
    $self->source_node_alias($source_node_alias);
    $self->source_name($source_name);
}

sub is_internal { return 1; }
sub is_input { return 0; }
sub is_output { return 0; }
sub is_constant { return 0; }

1;

package Compiler::AST::Coupler::Output;

use Moose;
use warnings FATAL => 'all';

extends 'Compiler::AST::Coupler';

has output_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub is_internal { return 0; }
sub is_input { return 0; }
sub is_output { return 1; }
sub is_constant { return 0; }


1;

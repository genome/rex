package Compiler::AST::Coupler::Constant;

use Moose;
use warnings FATAL => 'all';

extends 'Compiler::AST::Coupler';

has value => (
    is => 'ro',
    isa => 'Value',
    required => 1,
);

sub is_internal { return 0; }
sub is_input { return 1; }
sub is_output { return 0; }
sub is_constant { return 1; }


1;

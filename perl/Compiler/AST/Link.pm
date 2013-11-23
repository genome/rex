package Compiler::AST::Link;

use Moose;
use warnings FATAL => 'all';

has source => (
    is => 'ro',
    isa => 'Compiler::AST::DataEndPoint',
);
has destination => (
    is => 'ro',
    isa => 'Compiler::AST::DataEndPoint',
);

1;

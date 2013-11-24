package Compiler::AST::DataEndPoint;

use Moose;
use warnings FATAL => 'all';

has 'node' => (
    is => 'ro',
    isa => 'Compiler::AST::Node',
    required => 1,
);
has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'tags' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);
has 'is_used' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

1;

package Compiler::AST::Definition;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);


class Compiler::AST::Definition {
    id_generator => '-uuid',
    is_abstract => 1,
};

sub workflow_builder { confess 'Abstract method'; }
sub inputs { confess 'Abstract method'; }
sub outputs { confess 'Abstract method'; }


1;

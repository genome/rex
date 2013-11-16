package Compiler::Parser;

use strict;
use warnings 'FATAL' => 'all';

use Carp qw(confess);

use File::Basename qw();
use File::Spec qw();
use File::Slurp qw();

use Parse::RecDescent qw();
use Compiler::AST::Node;
use Compiler::AST::Definition::Process;
use Compiler::AST::Link::Internal;
use Compiler::AST::Link::Constant;

use Memoize qw();


sub parse_tree {
    my $input_path = shift;

    return _parse_tree_generator()->start(_slurp_scalar($input_path))
        or confess "Syntax error";
}

sub _parse_tree_generator {
    return new Parse::RecDescent(_slurp_scalar(_grammar_path()))
        or confess "Illegal grammar";
}
Memoize::memoize('_parse_tree_generator');

sub _grammar_path {
    return File::Spec->join(_base_path(), 'gms.grammar');
}

sub _base_path {
    return File::Basename::dirname(File::Spec->rel2abs(__FILE__));
}

sub _slurp_scalar {
    my $input_path = shift;

    my $force_scalar = File::Slurp::read_file($input_path);
    return $force_scalar;
}

1;

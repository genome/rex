package Compiler::Parser;

use strict;
use warnings 'FATAL' => 'all';

use UR;
use Carp qw(confess);

use File::Basename qw();
use File::Spec qw();
use File::Slurp qw();

use Parse::RecDescent qw();

use Memoize qw();

class Compiler::Parser {};


sub parse_tree {
    my ($self, $input_path) = @_;

    return parse_tree_generator()->start(input($input_path))
        or confess "Syntax error";
}

sub input {
    my $input_path = shift;

    my $force_scalar = File::Slurp::read_file($input_path);
    return $force_scalar;
}

sub parse_tree_generator {
    return new Parse::RecDescent(grammar())
        or confess "Illegal grammar";
}
Memoize::memoize('parse_tree_generator');

sub grammar {
    my $force_scalar = File::Slurp::read_file(_grammar_path());
    return $force_scalar;
}

sub _grammar_path {
    return File::Spec->join(_base_path(), 'process-definition.grammar');
}

sub _base_path {
    return File::Basename::dirname(File::Spec->rel2abs(_module_path()));
}

sub _module_path {
    my $module_path = sprintf("%s.pm", __PACKAGE__);
    $module_path =~ s|::|/|g;

    return $INC{$module_path};
}

1;

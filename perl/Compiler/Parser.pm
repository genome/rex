package Compiler::Parser;

use strict;
use warnings 'FATAL' => 'all';

use UR;
use Carp qw(confess);

use File::Basename qw();
use File::Spec qw();
use File::Slurp qw();

use Parse::RecDescent qw();

class Compiler::Parser {
    is => 'Command::V2',

    has_input => [
        input_file => {
            is => 'Path',
            shell_args_position => 1,
        },
    ],
};


sub execute {
    my $self = shift;

    my $tree = $self->parse_tree;
    use Data::Dumper;
    print Data::Dumper::Dumper($tree);

    1;
}

sub parse_tree {
    my $self = shift;

    my $parse_tree_generator = new Parse::RecDescent($self->_autotree_grammar)
        or confess "Illegal grammar";
    return $parse_tree_generator->process_definition($self->input)
        or confess "Syntax error";
}

sub input {
    my $self = shift;

    my $force_scalar = File::Slurp::read_file($self->input_file);
    return $force_scalar;
}

sub _autotree_grammar {
    my $self = shift;
    return sprintf("<autotree>\n\n%s", $self->grammar);
}

sub grammar {
    my $self = shift;

    my $force_scalar = File::Slurp::read_file($self->_grammar_path);
    return $force_scalar;
}

sub _grammar_path {
    my $self = shift;

    return File::Spec->join($self->_base_path, 'process-definition.grammar');
}

sub _base_path {
    my $self = shift;
    return File::Basename::dirname(File::Spec->rel2abs($self->_module_path));
}

sub _module_path {
    my $self = shift;

    my $module_path = sprintf("%s.pm", __PACKAGE__);
    $module_path =~ s|::|/|g;

    return $INC{$module_path};
}

1;

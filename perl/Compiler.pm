package Compiler;

use strict;
use warnings FATAL => 'all';

use UR;
use Data::Dumper;

use Compiler::Parser;
use Compiler::Importer;


class Compiler {
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
    my $parse_tree = Compiler::Parser::parse_tree($self->input_file);
    die 'Syntax error' unless $parse_tree;
    print Data::Dumper::Dumper($parse_tree);

    my $importer = Compiler::Importer->create(
        search_path => $self->search_path);

    my $result = {};
    go_recursive($importer, $parse_tree, $result);

    print Data::Dumper::Dumper($result);
}

sub go_recursive {
    my ($importer, $tree, $result) = @_;
    for my $op (@{$tree->{operations}}) {
        my $imported_stuff = $importer->import_file($op->{operation_type});
        if ($imported_stuff->{type} eq 'tool') {
            $result->{$op->{operation_type}} = $imported_stuff;
        } else {
            my $inner_result = {};
            go_recursive($importer, $imported_stuff, $inner_result);
            $result->{$op->{operation_type}} = $inner_result;
        }
    }
}

sub search_path {
    return ['tool-definitions', 'process-definitions'];
}

1;

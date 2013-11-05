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
}


sub search_path {
    return ['tool-definitions', 'process-definitions'];
}

1;

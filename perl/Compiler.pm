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
    my $parser = Compiler::Parser->create(input_file => $self->input_file);
    my $parse_tree = $parser->parse_tree;
    print Data::Dumper::Dumper($parse_tree);

    my $importer = Compiler::Importer->create(
        search_path => $self->search_path);
    printf("resolved path: %s\n", $importer->resolve_path("Foo/Bar"));
}


sub search_path {
    return ['tool-definitions'];
}

1;

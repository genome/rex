package Compiler;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use Data::Dumper;

use Compiler::Parser;
use Compiler::Importer;

use Compiler::AST::Tool;
use Compiler::AST::Process;


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
    printf("Root parse tree: %s\n", Data::Dumper::Dumper($parse_tree));

    my $importer = Compiler::Importer->create(
        search_path => $self->search_path);

    my $result = get_process_object($importer, $parse_tree);

    printf("AST: %s\n", Data::Dumper::Dumper($result));
}

sub get_process_object {
    my ($importer, $process) = @_;

    die 'not an actual process object'
        unless $process->{type} eq 'process';

    my @children = get_children($importer,
        $process->{operations});

    return Compiler::AST::Process->create(
        operation_type => $process->{operation_type},
        children => \@children);
}

sub get_children {
    my ($importer, $operation_definitions) = @_;

    my @children;
    for my $op (@$operation_definitions) {

        my $imported_stuff = $importer->import_file($op->{operation_type});
        if ($imported_stuff->{type} eq 'tool') {
            push @children, Compiler::AST::Tool->create(
                operation_type => $op->{operation_type});
            # imported stuff will contain inputs, etc.

        } elsif ($imported_stuff->{type} eq 'process') {
            my @grand_children = get_children($importer,
                $imported_stuff->{operations});

            push @children, Compiler::AST::Process->create(
                operation_type => $op->{operation_type},
                children => \@grand_children);

        } else {
            confess sprintf("Unknown type: %s", $imported_stuff->{type});
        }
    }
    return @children;
}

sub search_path {
    return ['tool-definitions', 'process-definitions'];
}

1;

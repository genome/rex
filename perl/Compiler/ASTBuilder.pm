package Compiler::ASTBuilder;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use Compiler::AST::Tool;
use Compiler::AST::Process;


sub build_AST {
    my ($importer, $parse_tree) = @_;

    return _get_process_object($importer, $parse_tree, 'root');
}


sub _get_process_object {
    my ($importer, $process, $operation_type) = @_;

    die 'not an actual process object'
        unless $process->{kind} eq 'process';

    my @children = _get_children($importer,
        $process->{operations});

    return Compiler::AST::Process->create(
        alias => $operation_type,
        operation_type => $operation_type,
        children => \@children);
}

sub _get_children {
    my ($importer, $operation_definitions) = @_;

    my @children;
    for my $op (@$operation_definitions) {
        my $imported_stuff = $importer->import_file($op->{type});

        if ($imported_stuff->{kind} eq 'tool') {
            push @children, Compiler::AST::Tool->create(
                alias => $op->{alias},
                operation_type => $op->{type},
                command => $imported_stuff->{command},
                input_entry => _build_io_entries($imported_stuff->{inputs}),
                output_entry => _build_io_entries($imported_stuff->{outputs}),
            );

        } elsif ($imported_stuff->{kind} eq 'process') {
            my @grand_children = _get_children($importer,
                $imported_stuff->{operations});

            push @children, Compiler::AST::Process->create(
                alias => $op->{alias},
                operation_type => $op->{type},
                children => \@grand_children);

        } else {
            confess sprintf("Unknown type: %s",
                $imported_stuff->{type});
        }
    }
    return @children;
}


sub _build_io_entries {
    my $maybe_entries = shift;

    unless (scalar(@$maybe_entries)) {
        return [];
    }

    return [map {Compiler::AST::IOEntry->create(%{$_})}
        @{$maybe_entries->[0]}];
}


1;

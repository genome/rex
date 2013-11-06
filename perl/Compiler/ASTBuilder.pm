package Compiler::ASTBuilder;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use Compiler::AST::Tool;
use Compiler::AST::Process;


sub build_AST {
    my ($importer, $parse_tree) = @_;

    return _get_process_object($importer, $parse_tree);
}


sub _get_process_object {
    my ($importer, $process) = @_;

    die 'not an actual process object'
        unless $process->{type} eq 'process';

    my @children = _get_children($importer,
        $process->{operations});

    return Compiler::AST::Process->create(
        operation_type => $process->{operation_type},
        children => \@children);
}

sub _get_children {
    my ($importer, $operation_definitions) = @_;

    my @children;
    for my $op (@$operation_definitions) {
        my $imported_stuff = $importer->import_file($op->{operation_type});
        # TODO Make sure we don't infinitely recurse.

        if ($imported_stuff->{type} eq 'tool') {
            push @children, Compiler::AST::Tool->create(
                operation_type => $op->{operation_type},
                command => $imported_stuff->{command},
                input_entry => _build_io_entries($imported_stuff->{inputs}),
                output_entry => _build_io_entries($imported_stuff->{outputs}),
            );

        } elsif ($imported_stuff->{type} eq 'process') {
             my @grand_children = _get_children($importer,
                 $imported_stuff->{operations});

             push @children, Compiler::AST::Process->create(
                 operation_type => $op->{operation_type},
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

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

    return Compiler::AST::Process->create(
        operation_type => $operation_type,
        children => _get_children($importer, $process->{operations}));
}

sub _get_children {
    my ($importer, $operation_definitions) = @_;

    my %children;
    for my $op (@$operation_definitions) {
        my $imported_stuff = $importer->import_file($op->{type});
        if (exists $children{$op->{alias}}) {
            confess sprintf(
                "Multiple children with same alias (%s) in process '%s'",
                $op->{alias}, $imported_stuff->{type});
        }

        my $explicit_link_info = _get_explicit_link_info(
            $op->{inputs}, $op->{alias});

        if ($imported_stuff->{kind} eq 'tool') {
            $children{$op->{alias}} = Compiler::AST::Tool->create(
                operation_type => $op->{type},
                command => $imported_stuff->{command},
                input_entry => _build_io_entries($imported_stuff->{inputs}),
                output_entry => _build_io_entries($imported_stuff->{outputs}),
                explicit_link_info => $explicit_link_info,
            );

        } elsif ($imported_stuff->{kind} eq 'process') {
            $children{$op->{alias}} =Compiler::AST::Process->create(
                operation_type => $op->{type},
                explicit_link_info => $explicit_link_info,
                children => _get_children($importer,
                    $imported_stuff->{operations}),
            );

        } else {
            confess sprintf("Unknown type: %s",
                $imported_stuff->{type});
        }
    }

    return \%children;
}

sub _build_io_entries {
    my $maybe_entries = shift;

    unless (scalar(@$maybe_entries)) {
        return [];
    }

    return [map {Compiler::AST::IOEntry->create(%{$_})}
        @{$maybe_entries->[0]}];
}

sub _get_explicit_link_info {
    my ($inputs, $alias) = @_;

    my %explicit_link_info;
    for my $input (@$inputs) {
        my ($key, $value);
        if ($input->{type} eq 'link') {
            $key = $input->{property_name};
            $value = $input->{source};
        } elsif ($input->{type} eq 'constant') {
            # Since workflow xml has no concept of a constant we will treat
            # them as an input link.
            $key = $input->{property_name};
            $value = 'inputs';
        }
        if (exists $explicit_link_info{$key}) {
            confess sprintf(
                "multiple sources named for input (%s) of operation %s: ".
                "%s and %s", $key, $alias, $explicit_link_info{$key}, $value);
        } else {
            $explicit_link_info{$key} = $value;
        }
    }
    return \%explicit_link_info;
}


1;

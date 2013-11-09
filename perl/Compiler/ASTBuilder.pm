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
        explicit_link_info => _get_explicit_link_info($process->{operations}),
        children => _get_children($importer, $process->{operations}));
}

sub _get_explicit_link_info {
    my $operations = shift;

    my %info;
    for my $op (@$operations) {
        for my $input (@{$op->{inputs}}) {
            if (exists $info{internal}{$op->{alias}}{$input->{property_name}}) {
                confess sprintf("Multiple values specified for %s.%s",
                    $op->{alias}, $input->{property_name});
            }

            if ($input->{type} eq 'link') {
                $info{internal}{$op->{alias}}{$input->{property_name}} = {
                    alias => $input->{source},
                    type => $input->{type},
                };
            } elsif ($input->{type} eq 'constant') {
                $info{input}{$op->{alias}}{$input->{property_name}} = {
                    type => $input->{type},
                    value => $input->{value},
                };
            }
        }
    }

    return \%info || undef;  # UR doesn't like empty hashes
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

        } else {
            $children{$op->{alias}} = _get_child($importer,
                $op, $imported_stuff);
        }
    }

    return \%children;
}

sub _get_child {
    my ($importer, $op, $imported_stuff) = @_;

    if ($imported_stuff->{kind} eq 'tool') {
        return Compiler::AST::Tool->create(
            operation_type => $op->{type},
            command => $imported_stuff->{command},
            input_entry => _build_io_entries($imported_stuff->{inputs}),
            output_entry => _build_io_entries($imported_stuff->{outputs}),
        );

    } elsif ($imported_stuff->{kind} eq 'process') {
        return Compiler::AST::Process->create(
            operation_type => $op->{type},
            explicit_link_info => _get_explicit_link_info(
                $imported_stuff->{operations}),
            children => _get_children($importer,
                $imported_stuff->{operations}),
        );

    } else {
        confess sprintf("Unknown kind: %s", $imported_stuff->{kind});
    }
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

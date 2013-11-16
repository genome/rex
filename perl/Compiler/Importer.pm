package Compiler::Importer;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Spec qw();

use Compiler::Parser;
use Compiler::AST::Definition::Tool;
use Compiler::AST::IO::Input;
use Compiler::AST::IO::Output;

use constant EXTENSION => '.gms';


sub import_file {
    my $name = shift;

    my $process_definition_path = resolve_path($name);
    if ($process_definition_path) {
        return Compiler::Parser::parse_tree($process_definition_path);
    } else {
        return create_tool_definition($name);
    }
}


sub resolve_path {
    my $name = shift;
    my $relative_path = $name . EXTENSION();

    for my $base_path (search_path()) {
        my $absolute_path = File::Spec->rel2abs(File::Spec->join(
                $base_path, split(/::/, $relative_path)));
        if (-f $absolute_path) {
            return $absolute_path;
        }
    }

    return;
}

sub search_path {
    if ($ENV{GMSPATH}) {
        return split(/:/, $ENV{GMSPATH});
    }
    return 'definitions';
}


sub create_tool_definition {
    my $tool_class_name = shift;

    eval "use $tool_class_name";
    if ($@) {
        confess sprintf("Couldn't use tool '%s': %s", $tool_class_name, $@);
    }
    my $inputs = _create_tool_inputs($tool_class_name);
    my $outputs = _create_tool_outputs($tool_class_name);

    return Compiler::AST::Definition::Tool->create(command => $tool_class_name,
        inputs => $inputs, outputs => $outputs);
}

sub _create_tool_inputs {
    my $tool_class_name = shift;

    my $input_hash = $tool_class_name->ast_inputs;
    my @result;
    for my $name (keys %$input_hash) {
        push @result, Compiler::AST::IO::Input->create(name => $name,
            type => $input_hash->{$name});
    }

    return \@result;
}

sub _create_tool_outputs {
    my $tool_class_name = shift;

    my $output_hash = $tool_class_name->ast_outputs;
    my @result;
    for my $name (keys %$output_hash) {
        push @result, Compiler::AST::IO::Output->create(name => $name,
            type => $output_hash->{$name});
    }

    return \@result;
}


1;

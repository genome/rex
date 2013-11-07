package Compiler;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use Data::Dumper;

use Compiler::Parser;
use Compiler::Importer;
use Compiler::ASTBuilder;

use File::Slurp qw();
use File::Spec qw();
use File::Path qw();

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

    $self->make_output_directory;

    $self->save_data('parse_tree', Data::Dumper::Dumper($parse_tree));

    my $importer = Compiler::Importer->create(
        search_path => $self->search_path);

    my $ast = Compiler::ASTBuilder::build_AST($importer, $parse_tree);
    $self->save_data('ast', Data::Dumper::Dumper($ast));

    $self->save_data('inputs', Data::Dumper::Dumper($ast->inputs));
    $self->save_data('outputs', Data::Dumper::Dumper($ast->outputs));

    $self->save_data('workflow.xml', $ast->workflow_builder->get_xml);
    $self->format_xml('workflow.xml');
#    my $outputs = $ast->workflow_builder->execute(
#        'input:T1' => 'foo1',
#        'input:T2' => 'foo2',
#        'input:T3' => 'foo3');
#    print Data::Dumper::Dumper($outputs);
    return 1;
}

sub search_path {
    return ['tool-definitions', 'process-definitions'];
}

sub output_directory {
    my $self = shift;

    my $path = $self->input_file;
    $path =~ s/\.gms$//;
    return $path . '/';
}

sub make_output_directory {
    my $self = shift;

    File::Path::remove_tree($self->output_directory);
    File::Path::make_path($self->output_directory);
    return;
}

sub save_data {
    my ($self, $filename, $data) = @_;

    File::Slurp::write_file($self->output_path($filename), $data);

    return;
}

sub output_path {
    my ($self, $filename) = @_;

    return File::Spec->join($self->output_directory, $filename);
}

sub format_xml {
    my ($self, $filename) = @_;

    system sprintf("xmltidy %s", $self->output_path($filename));

    return;
}


1;

package Compiler;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use Data::Dumper;

use Compiler::Parser;

use File::Slurp qw();
use File::Spec qw();
use File::Path qw();

use IO::File qw();

use InputFile;


class Compiler {
    is => 'Command::V2',

    has_input => [
        input_file => {
            is => 'Path',
            shell_args_position => 1,
        },

        output_directory => {
            is => 'Path',
            is_optional => 1,
        },
    ],
};


sub execute {
    my $self = shift;

    my $ast = Compiler::Parser::parse_tree($self->input_file);

    $self->make_output_directory;

    my @inputs = $ast->inputs;
    $self->save_inputs_with_constants(\@inputs, $ast->constants);

    $self->save_data('workflow.xml', $ast->workflow_builder('root')->get_xml);
    $self->format_xml('workflow.xml');

    return 1;
}

sub save_inputs_with_constants {
    my ($self, $inputs, $constants) = @_;

    my $input_file = InputFile->create_from_inputs_and_constants(
        $inputs, $constants);

    my $file_handle = IO::File->new($self->output_path('inputs.tsv'), 'w');
    $input_file->write($file_handle);
    $file_handle->close;

    return;
}

sub get_output_directory {
    my $self = shift;

    return $self->output_directory if $self->output_directory;
    return $self->default_output_directory;
}

sub default_output_directory {
    my $self = shift;

    my $path = $self->input_file;
    $path =~ s/\.gms$//;
    return $path . '/';
}

sub make_output_directory {
    my $self = shift;

    File::Path::remove_tree($self->get_output_directory);
    File::Path::make_path($self->get_output_directory);
    return;
}

sub save_data {
    my ($self, $filename, $data) = @_;

    File::Slurp::write_file($self->output_path($filename), $data);

    return;
}

sub output_path {
    my ($self, $filename) = @_;

    return File::Spec->join($self->get_output_directory, $filename);
}

sub format_xml {
    my ($self, $filename) = @_;

    system sprintf("xmltidy %s", $self->output_path($filename));

    return;
}


1;

package CLI::Process::Start;

use strict;
use warnings FATAL => 'all';

use UR;

use Tool;
use Compiler;
use Runner;

use File::Spec qw();
use File::Temp qw();
use IPC::Run qw();


class CLI::Process::Start {
    is => 'Command::V2',

    has => [
        definition => {
            is => 'Path',
        },

        inputs => {
            is => 'Path',
        },
    ],

    has_transient => [
        _tempdir => {
            is => 'Path',
            is_optional => 1,
        },
    ],
};


sub execute {
    my $self = shift;

    $self->_tempdir(File::Temp::tempdir(CLEANUP => 1));

    $self->compile;
    $self->set_inputs;
    return $self->run;
}


sub compile {
    my $self = shift;

    my $compiler = Compiler->new('input-file' => $self->definition,
        'output-directory' => $self->_tempdir);
    $compiler->execute;

    return;
}

sub set_inputs {
    my $self = shift;

    my $compiler_inputs = InputFile->create_from_filename(
        $self->_compiler_inputs_tsv);

    my $user_specified_inputs = InputFile->create_from_filename(
        $self->inputs);

    $compiler_inputs->update($user_specified_inputs);

    $compiler_inputs->write_to_filename($self->_final_inputs_tsv);

    return;
}

sub _compiler_inputs_tsv {
    my $self = shift;

    return File::Spec->join($self->_tempdir, 'inputs.tsv');
}

sub run {
    my $self = shift;

    my $runner = Runner->create(workflow => $self->_workflow_xml,
        inputs => $self->_final_inputs_tsv);
    return $runner->execute;
}

sub _workflow_xml {
    my $self = shift;

    return File::Spec->join($self->_tempdir, 'workflow.xml');
}

sub _final_inputs_tsv {
    my $self = shift;

    return File::Spec->join($self->_tempdir, 'final-inputs.tsv');
}


1;

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
    return $self->run;
}


sub compile {
    my $self = shift;

    my $compiler = Compiler->new('input-file' => $self->definition,
        'output-directory' => $self->_tempdir);
    $compiler->execute;

    return;
}

sub _compiler_inputs_tsv {
    my $self = shift;

    return File::Spec->join($self->_tempdir, 'inputs.tsv');
}

sub run {
    my $self = shift;

    my $runner = Runner->new(workflow => $self->_workflow_xml,
        inputs => [$self->_compiler_inputs_tsv, $self->inputs]);
    return $runner->execute;
}

sub _workflow_xml {
    my $self = shift;

    return File::Spec->join($self->_tempdir, 'workflow.xml');
}


1;

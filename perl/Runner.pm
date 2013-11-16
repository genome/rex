package Runner;

use strict;
use warnings FATAL => 'all';

use UR;
use Genome::WorkflowBuilder::DAG;

use IO::File qw();
use InputFile;
use Factory::Process;


class Runner {
    is => 'Command::V2',

    has_input => [
        workflow => {
            is => 'Path',
        },

        inputs => {
            is => 'Path',
        },
    ],

    has_optional_output => [
        outputs => {
            is => 'HASH',
        },
    ],
};


sub execute {
    my $self = shift;

    my $process = Factory::Process::new();
    $self->status_message('Launching Process %s (%s)', $process->id,
        $process->log_directory);

    my $inputs_file = $self->inputs_file($process);

    my $dag = Genome::WorkflowBuilder::DAG->from_xml_filename($self->workflow);
    $dag->log_dir($process->log_directory);

    $process->save_workflow($dag);
    $process->save_inputs($inputs_file);

    UR::Context->commit;
    $self->outputs($dag->execute($inputs_file->as_hash));

    1;
}

sub inputs_file {
    my ($self, $process) = @_;

    my $inputs_fh = IO::File->new($self->inputs, 'r');
    my $input_file = InputFile->create_from_file_handle($inputs_fh);
    $inputs_fh->close;

    my $process_input_name = $input_file->unique_input_name_for('PROCESS');
    $input_file->set_inputs($process_input_name => $process->url);

    return $input_file;
}


1;

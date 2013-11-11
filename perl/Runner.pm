package Runner;

use strict;
use warnings FATAL => 'all';

use UR;
use Genome::WorkflowBuilder::DAG;

use IO::File qw();
use InputFile;


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

    my %inputs_hash = $self->inputs_hash;
    my $dag = Genome::WorkflowBuilder::DAG->from_xml_filename($self->workflow);

    $self->outputs($dag->execute(%inputs_hash));

    1;
}

sub inputs_hash {
    my $self = shift;

    my $inputs_fh = IO::File->new($self->inputs, 'r');
    my $input_file = InputFile->create_from_file_handle($inputs_fh);
    $inputs_fh->close;

    return $input_file->as_hash;
}


1;

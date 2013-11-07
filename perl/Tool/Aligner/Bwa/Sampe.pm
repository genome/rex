package Tool::Aligner::Bwa::Sampe;

use strict;
use warnings FATAL => 'all';

use UR;

class Tool::Aligner::Bwa::Sampe {
    is => 'Command::V2',
    has_input => [
        alignment_index => {
            is => "File",
        },
        first_sai => {
            is => "File",
        },
        second_sai => {
            is => "File",
        },
        max_insert_size => {
            is => "Number",
        },
        unaligned_bam => {
            is => "File",
        },
    ],
    has_output => [
        output_file => {
            is => "File",
        },
    ],
};

sub execute {
    my $self = shift;

    printf("Running sampe with params:\nmax_insert_size:%s\n", $self->max_insert_size);
    $self->set_outputs();

    return 1;
}

sub set_outputs {
    my $self = shift;

    $self->output_file('Bar');
}

1;


package Tool::Aligner::Bwa::Aln;

use strict;
use warnings FATAL => 'all';

use UR;

class Tool::Aligner::Bwa::Aln {
    is => 'Command::V2',
    has_input => [
        input_bam => {
            is => "File",
        },
        alignment_index => {
            is => "File",
        },
        read_mode => {
            is => "Number",
            valid_values => [0,1,2],
        },
        threads => {
            is => "Number",
        },
        trimming_quality_threshold => {
            is => "Number",
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

    printf("Running aln with params:\nread_mode:%s\n", $self->read_mode);
    $self->set_outputs();

    return 1;
}

sub set_outputs {
    my $self = shift;

    $self->output_file('Foo');
}

1;

package Tool::Samtools::SamToBam;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use IPC::Run qw();


class Tool::Samtools::SamToBam {
    is => 'Tool::Base',

    has_input => [
        input_sam => {
            is => "File",
            dsl_type => 'File::Sam::Aligned',
        },
    ],

    has_output => [
        output_bam => {
            is => "File",
            dsl_type => 'File::Bam::Aligned',
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->output_bam($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->output_bam);

    return;
}


sub _create_output_filename {
    my $self = shift;

    return 'sam-to-bam.bam';
}

sub command_line {
    my $self = shift;

    return ['samtools', 'view', '-Sb', $self->input_sam];
}


1;

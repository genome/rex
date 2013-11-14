package Tool::Samtools::SamToBam;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Temp qw();
use IPC::Run qw();


class Tool::Samtools::SamToBam {
    is => 'Tool::Base',

    has_input => [
        input_sam => {
            is => "File",
        },
    ],

    has_output => [
        output_bam => {
            is => "File",
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->output_bam($self->_create_output_filename);
    $self->status_message(sprintf('Writing bam file to %s', $self->output_bam));
    IPC::Run::run($self->command_line, '>', $self->output_bam);

    return;
}


sub _create_output_filename {
    my $self = shift;

    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.bam');

    return $fh->filename;
}

sub command_line {
    my $self = shift;

    return ['samtools', 'view', '-Sb', $self->input_sam];
}


1;

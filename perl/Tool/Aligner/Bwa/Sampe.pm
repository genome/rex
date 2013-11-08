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
        unaligned_bam => {
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
    ],

    has_output => [
        output_file => {
            is => "File",
        },
    ],
};

sub execute {
    my $self = shift;

    $self->output_file($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->output_file);

    return 1;
}

sub command_line {
    my $self = shift;

    return ['bwa', 'sampe',
        $self->alignment_index,
        $self->first_sai,
        $self->second_sai,
        $self->unaligned_bam,
        $self->unaligned_bam];
}


sub _create_output_filename {
    my $self = shift;

    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.sam');

    return $fh->filename;
}

1;

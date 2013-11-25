package Tool::Bwa::Sampe;

use strict;
use warnings FATAL => 'all';

use UR;
use IPC::Run qw();


class Tool::Bwa::Sampe {
    is => 'Tool::Base',

    has_input => [
        alignment_index => {
            is => "File",
            dsl_tags => [qw(file index bwa)],
        },
        unaligned_bam => {
            is => "File",
            dsl_tags => [qw(file bam unaligned paired)],
        },
        first_sai => {
            is => "File",
            dsl_tags => [qw(file sai)],
        },
        second_sai => {
            is => "File",
            dsl_tags => [qw(file sai)],
        },

        max_insert_size => {
            is => "Number",
            dsl_tags => [qw(integer param bwa sampe max_insert_size)],
        },
    ],

    has_output => [
        output_file => {
            is => "File",
            dsl_tags => [qw(file sam aligned paired)],
        },
    ],
};

sub execute_tool {
    my $self = shift;

    $self->output_file($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->output_file);

    return;
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

    return 'bwa-sampe.sam';
}


1;

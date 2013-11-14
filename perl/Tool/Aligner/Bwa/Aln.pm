package Tool::Aligner::Bwa::Aln;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use File::Temp qw();
use IPC::Run qw();


class Tool::Aligner::Bwa::Aln {
    is => 'Tool::Base',

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


sub execute_tool {
    my $self = shift;

    $self->output_file($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->output_file);

    return;
}


sub _create_output_filename {
    my $self = shift;

    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.sai');

    return $fh->filename;
}

sub command_line {
    my $self = shift;

    return ['bwa', 'aln', '-b',
        $self->_read_mode_param,
        $self->_threads_param,
        $self->_trimming_quality_threshold_param,
        $self->alignment_index,
        $self->input_bam];
}

sub _read_mode_param {
    my $self = shift;
    return sprintf("-%d", $self->read_mode);
}

sub _threads_param {
    my $self = shift;
    return ('-t', $self->threads);
}

sub _trimming_quality_threshold_param {
    my $self = shift;
    return ('-q', $self->trimming_quality_threshold);
}


1;

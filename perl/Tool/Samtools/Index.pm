package Tool::Samtools::Index;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


class Tool::Samtools::Index {
    is => 'Tool::Base',

    has_input => [
        input_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned position_sorted)],
        },
    ],

    has_output => [
        output_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned position_sorted indexed)],
        },
    ],

    has_optional_saved => [
        bam_index => {
            is => 'File',
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->_set_output_names;
    $self->_copy_input_bam;
    $self->_index_bam;

    return;
}

sub _set_output_names {
    my $self = shift;

    $self->output_bam('indexed.bam');
    $self->bam_index(sprintf("%s.bai", $self->output_bam));

    return;
}

sub _copy_input_bam {
    my $self = shift;

    my $status = File::Copy::copy($self->input_bam, $self->output_bam);
    unless ($status) {
        confess sprintf("Failed to copy input fasta (%s) to workspace: %s",
            $self->input_fasta, $status);
    }

    return;
}

sub _index_bam {
    my $self = shift;

    IPC::Run::run(['samtools', 'index', $self->output_bam, $self->bam_index]);
    return;
}


1;

package Tool::Aligner::Bwa::Index;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


class Tool::Aligner::Bwa::Index {
    is => 'Tool::Base',

    has_input => [
        input_fasta => {
            is => "File",
            dsl_type => 'File::Fasta',
        },
    ],

    has_output => [
        output_fasta => {
            is => "File",
            dsl_type => 'File::AlignerIndex::Bwa',
        },
    ],

    has_optional_saved => [
        amb_file => {
            is => "File",
        },
        ann_file => {
            is => "File",
        },
        bwt_file => {
            is => "File",
        },
        pac_file => {
            is => "File",
        },
        sa_file => {
            is => "File",
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->_set_output_filenames;
    $self->_copy_reference_fasta;
    IPC::Run::run($self->command_line);

    return;
}


sub _set_output_filenames {
    my $self = shift;

    $self->amb_file('reference.fa.amb');
    $self->ann_file('reference.fa.ann');
    $self->bwt_file('reference.fa.bwt');
    $self->output_fasta('reference.fa');
    $self->pac_file('reference.fa.pac');
    $self->sa_file('reference.fa.sa');

    return;
}

sub _copy_reference_fasta {
    my $self = shift;

    my $status = File::Copy::copy($self->input_fasta, $self->output_fasta);
    unless ($status) {
        confess sprintf("Failed to copy input fasta (%s) to workspace: %s",
            $self->input_fasta, $status);
    }

    return;
}

sub command_line {
    my $self = shift;

    return ['bwa', 'index', $self->output_fasta];
}


1;


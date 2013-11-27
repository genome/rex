package Tool::SomaticSniper;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


class Tool::SomaticSniper {
    is => 'Tool::Base',

    has_input => [
        normal_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned chromosome_sorted)],
        },
        tumor_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned chromosome_sorted)],
        },
        alignment_index => {
            is => "File",
            dsl_tags => [qw(file index bwa)],
        },
        version => {
            is => 'Text',
            dsl_tags => [qw(string param version somaticsniper)],
        },
    ],

    has_output => [
        snv_output => {
            is => "File",
            dsl_tags => [qw(file vcf snv somaticsniper)],
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->snv_output($self->_create_output_filename);
    IPC::Run::run($self->command_line);

    return;
}


sub _create_output_filename {
    return 'somatic-sniper-snvs.vcf';
}

sub command_line {
    my $self = shift;

    return [$self->_executable,
            '-F', 'vcf',
            '-f', $self->alignment_index,
            $self->tumor_bam, $self->normal_bam,
            $self->snv_output];
}

sub _executable {
    my $self = shift;
    return sprintf("bam-somaticsniper%s", $self->version);
}


1;

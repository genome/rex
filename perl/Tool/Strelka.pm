package Tool::Strelka;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();
use Config::IniFiles qw();


class Tool::Strelka {
    is => 'Tool::Base',

    has_input => [
        normal_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned position_sorted indexed)],
        },
        tumor_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned position_sorted indexed)],
        },
        alignment_index => {
            is => "File",
            dsl_tags => [qw(file index bwa)],
        },
        version => {
            is => 'Text',
            dsl_tags => [qw(string param version strelka)],
        },

        threads => {
            is => 'Number',
            dsl_tags => [qw(integer param threads strelka)],
        },
    ],

    has_output => [
        snv_output => {
            is => "File",
            dsl_tags => [qw(file vcf snv strelka)],
        },
        indel_output => {
            is => "File",
            dsl_tags => [qw(file vcf indel strelka)],
        },

        passed_snv_output => {
            is => "File",
            dsl_tags => [qw(file vcf snv strelka passed)],
        },
        passed_indel_output => {
            is => "File",
            dsl_tags => [qw(file vcf indel strelka passed)],
        },

    ],
};


sub execute_tool {
    my $self = shift;

    $self->_create_config_file;
    $self->_create_makefile;
    $self->_run_makefile;

    $self->_set_output_paths;

    return;
}

sub _create_config_file {
    my $self = shift;

    my $config_file = Config::IniFiles->new(
        -file => $self->_default_config_file_path);
    $self->_set_params($config_file);
    $config_file->WriteConfig($self->_config_file_path);

    return;
}

sub _default_config_file_path {
    my $self = shift;
    return File::Spec->join($self->_strelka_version_root, 'etc',
        'strelka_config_bwa_default.ini');
}

sub _strelka_version_root {
    my $self = shift;

    return sprintf('/usr/lib/strelka%s', $self->version);
}

sub _set_params {
    my $self = shift;

    return;
}

sub _config_file_path {
    return 'strelka_config.ini';
}

sub _create_makefile {
    my $self = shift;

    IPC::Run::run($self->_configure_command_line);

    return;
}

sub _configure_command_line {
    my $self = shift;
    return [$self->_configure_script_path,
        '--tumor', $self->tumor_bam,
        '--normal', $self->normal_bam,
        '--ref', $self->alignment_index,
        '--config', $self->_config_file_path]
}

sub _configure_script_path {
    my $self = shift;
    return File::Spec->join($self->_strelka_version_root, 'bin',
        'configureStrelkaWorkflow.pl');
}

sub _run_makefile {
    my $self = shift;

    IPC::Run::run(['make', '-j', $self->threads, '-C', 'strelkaAnalysis']);


    print "--- Begin Strelka STDOUT ---\n";
    print `find strelkaAnalysis -name "*.stdout" | xargs cat`;
    print "--- End Strelka STDOUT ---\n";

    print STDERR "--- Begin Strelka STDERR ---\n";
    print STDERR `find strelkaAnalysis -name "*.stderr" | xargs cat`;
    print STDERR "--- End Strelka STDERR ---\n";

    return;
}

sub _set_output_paths {
    my $self = shift;

    $self->snv_output('strelkaAnalysis/results/all.somatic.snvs.vcf');
    $self->indel_output('strelkaAnalysis/results/all.somatic.indels.vcf');
    $self->passed_snv_output('strelkaAnalysis/results/passed.somatic.snvs.vcf');
    $self->passed_indel_output(
        'strelkaAnalysis/results/passed.somatic.indels.vcf');

    return;
}


1;

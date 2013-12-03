package Tool::Bwa::Aln;
use Tool;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


has_input 'alignment_index';
has_input 'input_bam';

has_param 'read_mode';
has_param 'threads';
has_param 'trimming_quality_threshold';

has_output 'sai_file';


sub execute_tool {
    my $self = shift;

    $self->sai_file($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->sai_file);

    return;
}


sub _create_output_filename {
    my $self = shift;

    return 'bwa-aln.sai';
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


__PACKAGE__->meta->make_immutable;

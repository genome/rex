package Tool::Samtools::Sort;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use File::Temp qw();
use IPC::Run qw();


class Tool::Samtools::Sort {
    is => 'Command::V2',

    has_input => [
        input_bam => {
            is => "File",
        },
    ],

    has_output => [
        output_bam => {
            is => "File",
        },
    ],
};


sub execute {
    my $self = shift;

    $self->output_bam($self->_create_output_filename);
    $self->status_message(sprintf('Sorted bam file is %s', $self->output_bam));
    IPC::Run::run($self->command_line);

    return 1;
}


sub _create_output_filename {
    my $self = shift;

    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.bam');

    return $fh->filename;
}

sub command_line {
    my $self = shift;

    return ['samtools', 'sort', $self->input_bam, $self->_output_prefix];
}

sub _output_prefix {
    my $self = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse(
        $self->output_bam, '.bam');
    return File::Spec->join($path, $name);
}


1;

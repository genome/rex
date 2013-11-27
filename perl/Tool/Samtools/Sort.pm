package Tool::Samtools::Sort;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


class Tool::Samtools::Sort {
    is => 'Tool::Base',

    has_input => [
        input_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned)],
        },
    ],

    has_output => [
        output_bam => {
            is => "File",
            dsl_tags => [qw(file bam aligned position_sorted)],
        },
    ],
};


sub execute_tool {
    my $self = shift;

    $self->output_bam($self->_create_output_filename);
    IPC::Run::run($self->command_line);

    return;
}


sub _create_output_filename {
    my $self = shift;

    return 'sort.bam';
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

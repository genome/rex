package Tool::Samtools::Sort;
use Tool;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use IPC::Run qw();


has_input 'input_bam';
has_output 'output_bam';


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


__PACKAGE__->meta->make_immutable;

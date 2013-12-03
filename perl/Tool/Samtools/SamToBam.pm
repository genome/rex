package Tool::Samtools::SamToBam;
use Tool;
use warnings FATAL => 'all';

use Carp qw(confess);
use IPC::Run qw();


has_input 'sam_file';
has_output 'bam_file';


sub execute_tool {
    my $self = shift;

    $self->bam_file($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->bam_file);

    return;
}


sub _create_output_filename {
    my $self = shift;

    return 'sam-to-bam.bam';
}

sub command_line {
    my $self = shift;

    return ['samtools', 'view', '-Sb', $self->sam_file];
}


__PACKAGE__->meta->make_immutable;

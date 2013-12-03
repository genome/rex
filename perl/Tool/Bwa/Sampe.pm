package Tool::Bwa::Sampe;
use Tool;
use warnings FATAL => 'all';

use IPC::Run qw();


has_input 'alignment_index';
has_input 'first_sai';
has_input 'second_sai';
has_input 'unaligned_bam';

has_param 'max_insert_size';

has_output 'aligned_sam';


sub execute_tool {
    my $self = shift;

    $self->aligned_sam($self->_create_output_filename);
    IPC::Run::run($self->command_line, '>', $self->aligned_sam);

    return;
}

sub command_line {
    my $self = shift;

    return ['bwa', 'sampe',
        $self->alignment_index,
        $self->first_sai,
        $self->second_sai,
        $self->unaligned_bam,
        $self->unaligned_bam];
}


sub _create_output_filename {
    my $self = shift;

    return 'bwa-sampe.sam';
}


__PACKAGE__->meta->make_immutable;

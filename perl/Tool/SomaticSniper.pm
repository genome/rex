package Tool::SomaticSniper;
use Tool;
use warnings FATAL => 'all';

use IPC::Run qw();


has_input 'alignment_index';
has_input 'normal_bam';
has_input 'tumor_bam';

has_param 'version';

has_output 'snv_output';


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


__PACKAGE__->meta->make_immutable;

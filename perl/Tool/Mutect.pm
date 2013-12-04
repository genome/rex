package Tool::Mutect;
use Tool;
use warnings FATAL => 'all';

use File::Spec qw();
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
    return 'mutect-snvs.vcf';
}

sub command_line {
    my $self = shift;

    return ['java', '-Xmx5g', '-jar', $self->_jar_path,
            '--analysis_type', 'MuTect',
            '--reference_sequence', $self->alignment_index,
            '--input_file:normal', $self->normal_bam,
            '--input_file:tumor', $self->tumor_bam,
            '--vcf', $self->snv_output];
}

sub _jar_path {
    my $self = shift;
    return File::Spec->join($self->_jar_path_base,
        sprintf("muTect-%s.jar", $self->version));
}

sub _jar_path_base {
    return '/gscuser/dlarson/mutect';
}

__PACKAGE__->meta->make_immutable;

package Process;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;
use Carp qw(confess);

use Params::Validate qw();
use File::Spec qw();
use File::Slurp qw();
use IO::File qw();


class Process {
    table_name => 'experimental.process',
    schema_name => 'GMSchema',
    data_source => 'Genome::DataSource::GMSchema',

    id_generator => '-uuid',

    id_by => [
        id => {
            is => 'Text',
            len => 36,
        },
    ],

    has => [
        status => {
            is => 'Text',
            len => 20,
            valid_values => ['new', 'running', 'failed', 'succeeded'],
        },

        allocation => {
            is => 'Genome::Disk::Allocation',
            id_by => 'allocation_id',
        },

        owner_id => {
            is => 'VARCHAR2',
            len => 1024,
        },
        owner => {
            is => 'UR::Object',
            id_by => 'owner_id',
            id_class_by => 'owner_class_name',
        },
    ],
};


sub log_directory {
    my $self = shift;

    return File::Spec->join($self->allocation->absolute_path, 'logs');
}


sub save_workflow {
    my ($self, $workflow_builder) = @_;

    File::Slurp::write_file($self->path('workflow.xml'),
        $workflow_builder->get_xml);

    return;
}

sub path {
    my ($self, $sub_path) = @_;

    return File::Spec->join($self->allocation->absolute_path, $sub_path);
}

sub save_inputs {
    my ($self, $input_file) = @_;

    my $file = IO::File->new($self->path('inputs.tsv'), 'w');
    $input_file->write($file);
    $file->close;

    return;
}


sub url {
    my $self = shift;

    return sprintf('gms:///process/%s', $self->id);
}

1;

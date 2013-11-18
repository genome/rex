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
use Data::UUID;
use Workflow;


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


sub workflow_name {
    my $self = shift;
    return sprintf("Process %s", $self->hyphenated_id);
}

sub hyphenated_id {
    my $self = shift;

    if (is_hyphenated($self->id)) {
        return $self->id;
    } else {
        my $ug = Data::UUID->new();
        my $uuid = $ug->from_hexstring('0x' . $self->id);
        return $ug->to_string($uuid);
    }
}

sub is_hyphenated {
    return $_[0] =~ /\-/;
}

sub workflow_instance {
    my $self = shift;
    my $force_scalar = Workflow::Operation::Instance->get(
        name => $self->workflow_name,
    );
    return $force_scalar;
}

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

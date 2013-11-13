package Result;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;
use Carp qw(confess);

use Manifest::Reader;
use File::Spec qw();
use Memoize qw();
use Params::Validate qw();

use JSON qw();

class Result {
    table_name => 'experimental.result',
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
        tool_class_name => {
            is => 'Text',
            len => 255,
        },
        allocation => {
            is => 'Genome::Disk::Allocation',
            id_by => 'allocation_id',
        },

        lookup_hash => {
            is => 'Text',
            len => 32
        },
    ],

    has_optional => [
        test_name => {
            is => 'Text',
            len => '255',
        },
    ],
};


sub lookup {
    my $class = shift;
    my %params = Params::Validate::validate(@_, {
            inputs => { type => Params::Validate::HASHREF },
            test_name => { type => Params::Validate::SCALAR, optional => 1 },
            tool_class_name => { type => Params::Validate::SCALAR },
        });

    my $force_scalar = $class->get(tool_class_name => $params{tool_class_name},
        lookup_hash => calculate_lookup_hash($params{inputs}),
        test_name => $params{test_name});
    return $force_scalar;
}

sub _validate_tool_inputs {
    my %params = Params::Validate::validate(@_, {
            inputs => { type => Params::Validate::HASHREF },
            tool_class_name => { type => Params::Validate::SCALAR },
        });

    require $params{tool_class_name};
    $params{tool_class_name}->validate_inputs($params{inputs});

    return;
}

sub calculate_lookup_hash {
    my $inputs = shift;

    _validate_inputs_structure($inputs);

    my $json = JSON->new();
    $json->canonical(1);
    my $json_string = $json->encode($inputs);

    return Genome::Sys->md5sum_data($json_string);
}


sub _validate_inputs_structure {
    my $inputs = shift;

    # XXX Make sure each value is a scalar or arrayref of scalars

    return;
}

sub create_from_manifest {
    my $class = shift;
}


sub path_to {
    my ($self, $tag) = @_;

    return $self->manifest->path_to($tag);
}


sub manifest {
    my $self = shift;

    return Manifest::Reader->create(manifest_path => $self->_manifest_path);
}
Memoize::memoize('manifest');

sub _manifest_path {
    my $self = shift;

    return File::Spec->join($self->allocation->absolute_path,
        'manifest.xml');
}


1;

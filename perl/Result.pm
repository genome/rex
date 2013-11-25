package Result;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;
use Carp qw(confess);

use Params::Validate qw();
use Result::Input;
use Result::Output;

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

        test_name => {
            is => 'Text',
            len => '255',
        },
    ],

    has_optional => [
        owner => {
            is => 'Process',
            id_by => 'process_id',
        },
    ],
};

sub inputs {
    my $self = shift;

    my @force_array = Result::Input->get(result_id => $self->id);
    return @force_array;
}

sub outputs {
    my $self = shift;

    my @force_array = Result::Output->get(result_id => $self->id);
    return @force_array;
}


sub lookup {
    my $class = shift;
    my %params = Params::Validate::validate(@_, {
            inputs => { type => Params::Validate::HASHREF },
            test_name => {
                type => Params::Validate::SCALAR,
                optional => 1, default => '' },
            tool_class_name => { type => Params::Validate::SCALAR },
        });

    my $lookup_hash = calculate_lookup_hash($params{inputs});
    $class->status_message("Attempting lookup for tool '%s' "
        . "with lookup_hash '%s' and test_name '%s'",
        $params{tool_class_name}, $lookup_hash, $params{test_name});

    my $force_scalar = $class->get(tool_class_name => $params{tool_class_name},
        lookup_hash => $lookup_hash, test_name => $params{test_name});
    return $force_scalar;
}

sub validate_for_lookup {
    my $class = shift;
    my %params = Params::Validate::validate(@_, {
            inputs => { type => Params::Validate::HASHREF },
            tool_class_name => { type => Params::Validate::SCALAR },
        });

    require $params{tool_class_name};
    $params{tool_class_name}->validate_inputs($params{inputs});

    _validate_inputs_structure($params{inputs});

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

sub update_lookup_hash {
    my $self = shift;

    my %inputs;
    for my $input ($self->inputs) {
        $inputs{$input->name} = $input->value_id;
    }

    $self->lookup_hash(calculate_lookup_hash(\%inputs));

    return;
}


1;

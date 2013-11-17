package Tool::Base;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use Translator;
use File::Temp qw();
use File::Path qw();
use Cwd qw();

use Manifest::Reader;
use Manifest::Writer;
use Factory::ManifestAllocation;

use Result;
use Result::Input;
use Result::Output;


class Tool::Base {
    is => 'Command::V2',
    is_abstract => 1,

    attributes_have => [
        is_contextual => {
            is => 'Boolean',
            is_optional => 1,
        },
        is_saved => {
            is => 'Boolean',
            is_optional => 1,
        },
        dsl_type => {
            is => 'Text',
#            is_optional => 0,
        },
    ],

    has_contextual_input => [
        process_ => {
            is => 'File',
            dsl_type => 'PROCESS',
        },
        test_name => {
            is => 'Text',
            dsl_type => 'TEST_NAME',
        },
    ],

    has_optional_transient => [
        _raw_inputs => {
            is => 'HASH',
        },
        _workspace_path => {
            is => 'Directory',
        },
        _original_working_directory => {
            is => 'Directory',
        },
    ],
};


sub shortcut {
    my $self = shift;

    $self->status_message('Attempting to shortcut %s with test name (%s)',
        $self->class, $self->test_name);

    my $result = Result->lookup(inputs => $self->_inputs_as_hashref,
        tool_class_name => $self->class, test_name => $self->test_name);

    if ($result) {
        $self->status_message('Found matching result with lookup hash (%s)',
            $result->lookup_hash);
        $self->_set_outputs_from_result($result);
        return 1;
    } else {
        $self->status_message('No matching result found for shortcut');
        return;
    }
}


sub _set_outputs_from_result {
    my ($self, $result) = @_;

    for my $output ($result->outputs) {
        my $name = $output->name;
        $self->$name($output->value_id);
    }

    return;
}


sub execute {
    my $self = shift;

    $self->_setup;

    eval {
        $self->execute_tool;
    };

    my $error = $@;
    if ($error) {
        unless ($ENV{GENOME_SAVE_WORKSPACE_ON_FAILURE}) {
            $self->_cleanup;
        }
        die $error;

    } else {
        $self->_save;
        $self->_cleanup;
    }

    return 1;
}

sub ast_inputs {
    my $class = shift;

    return $class->_property_type_hash(is_input => 1);
}

sub ast_outputs {
    my $class = shift;

    my $outputs = $class->_property_type_hash(is_output => 1);

    delete $outputs->{result};  #  result is legacy baggage
    return $outputs;
}

sub _property_type_hash {
    my $class = shift;

    my %result;
    for my $property ($class->__meta__->properties(@_)) {
        $result{$property->property_name} = $class->_get_dsl_type($property);
    }

    return \%result;
}

sub _get_dsl_type {
    my ($class, $property) = @_;

    my $meta = $class->__meta__->property_meta_for_name(
        $property->property_name);
    my $result = $meta->{dsl_type};

    return $result;
}


sub _setup {
    my $self = shift;

    $self->_setup_workspace;
    $self->_cache_raw_inputs;
    $self->_translate_inputs;

    return;
}

sub _cleanup {
    my $self = shift;

    chdir $self->_original_working_directory;
    File::Path::rmtree($self->_workspace_path);

    return;
}

sub _save {
    my $self = shift;

    $self->_verify_outputs_in_workspace;

    my $allocation = $self->_save_outputs;
    $self->_translate_outputs($allocation);
    $self->_create_checkpoint($allocation);

    return;
};

sub _verify_outputs_in_workspace { }

sub _setup_workspace {
    my $self = shift;

    $self->_workspace_path(File::Temp::tempdir(CLEANUP => 0));
    $self->_original_working_directory(Cwd::cwd());
    chdir $self->_workspace_path;

    return;
}

sub _cache_raw_inputs {
    my $self = shift;

    $self->_raw_inputs($self->_inputs_as_hashref);

    return;
}

sub _inputs_as_hashref {
    my $self = shift;

    my %inputs;
    for my $input_name ($self->_non_contextual_input_names) {
        $inputs{$input_name} = $self->$input_name;
    }

    return \%inputs;
}

sub _non_contextual_input_names {
    my $self = shift;

    return $self->_property_names(is_input => 1,
        is_contextual => undef), $self->_property_names(is_input => 1,
        is_contextual => 0);
}

sub _output_names {
    my $self = shift;

    return grep {'result' ne $_} $self->_property_names(is_output => 1);
}


sub _translate_inputs {
    my $self = shift;

    for my $input_name ($self->_translatable_input_names) {
        $self->$input_name(Translator::url_to_scalar($self->$input_name));
    }

    return;
}

my @_TRANSLATABLE_TYPES = (
    'File',
    'Process',
);
sub _translatable_input_names {
    my $self = shift;

    return map {$self->_property_names(is_input => 1, data_type => $_)}
        @_TRANSLATABLE_TYPES;
}

sub _translatable_output_names {
    my $self = shift;

    return map {$self->_property_names(is_output => 1, data_type => $_)}
        @_TRANSLATABLE_TYPES;
}


sub _save_outputs {
    my $self = shift;

    $self->_create_output_manifest;
    my $allocation = $self->_create_allocation_from_output_manifest;

    $self->status_message("Saved outputs from tool '%s' to allocation (%s)",
        $self->class, $allocation->id);
    $allocation->reallocate;

    return $allocation;
}

sub _create_output_manifest {
    my $self = shift;

    my $writer = Manifest::Writer->create(
        manifest_file => File::Spec->join($self->_workspace_path,
            'manifest.xml'));
    for my $output_name ($self->_saved_file_names) {
        next if $output_name eq 'result';  # legacy baggage

        my $path = $self->$output_name || '';
        if (-e $path) {
            $writer->add_file(path => $path, kilobytes => -s $path,
                tag => $output_name);
        }
    }
    $writer->save;

    return;
}

sub _create_allocation_from_output_manifest {
    my $self = shift;

    return Factory::ManifestAllocation::from_manifest(
        File::Spec->join($self->_workspace_path, 'manifest.xml'));
}


sub _saved_file_names {
    my $self = shift;

    return List::MoreUtils::uniq(
        $self->_property_names(is_output => 1, data_type => 'File'),
        $self->_property_names(is_saved => 1));
}

sub _property_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(@_);
}

sub _translate_outputs {
    my ($self, $allocation) = @_;

    for my $output_file_name ($self->_translatable_output_names) {
        $self->$output_file_name(
            _translate_output($allocation->id, $output_file_name)
        );
    }

    return;
}

sub _translate_output {
    my ($allocation_id, $tag) = @_;

    return sprintf('gms:///data/%s?tag=%s', $allocation_id, $tag);
}

sub _create_checkpoint {
    my ($self, $allocation) = @_;

    my $result = Result->create(tool_class_name => $self->class,
        test_name => $self->test_name, allocation => $allocation,
        process => $self->process_);

    for my $input_name ($self->_non_contextual_input_names) {
        my $input = Result::Input->create(name => $input_name,
            value_class_name => 'UR::Value',
            value_id => $self->_raw_inputs->{$input_name},
            result_id => $result->id);
    }

    for my $output_name ($self->_output_names) {
        Result::Output->create(name => $output_name,
            value_class_name => 'UR::Value',
            value_id => $self->$output_name,
            result_id => $result->id);
    }

    $result->update_lookup_hash;

    return;
}


1;

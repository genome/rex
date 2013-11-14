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

#use Checkpoint;


class Tool::Base {
    is => 'Command::V2',
    is_abstract => 1,

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


#sub shortcut {
#    my $self = shift;
#
#    my $result = Checkpoint->lookup(inputs => $self->_inputs_as_hashref,
#        tool_class_name => $self->class, test_name => $self->_test_name);
#
#    if ($result) {
#        $self->_set_outputs_from_result($result);
#        return 1;
#    } else {
#        return;
#    }
#}

#sub _test_name {
#    return $ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || undef;
#}


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

    $self->_save_and_translate_outputs;
    $self->_create_checkpoint;

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
    for my $input_name ($self->_input_names) {
        $inputs{$input_name} = $self->$input_name;
    }

    return \%inputs;
}

sub _input_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(is_input => 1);
}

sub _translate_inputs {
    my $self = shift;

    for my $input_name ($self->_input_file_names) {
        $self->$input_name(Translator::url_to_scalar($self->$input_name));
    }

    return;
}

sub _input_file_names {
    my $self = shift;

    return $self->_property_names(is_input => 1, data_type => 'File');
}

sub _save_and_translate_outputs {
    my $self = shift;

    my $allocation = $self->_save_outputs;
    $self->_translate_outputs($allocation);
}

sub _save_outputs {
    my $self = shift;

    $self->_create_output_manifest;
    my $allocation = $self->_create_allocation_from_output_manifest;

    $self->status_message("Saving outputs from tool '%s' to allocation (%s)",
        $self->class, $allocation->id);

    return $allocation;
}

sub _create_output_manifest {
    my $self = shift;

    my $writer = Manifest::Writer->create(
        manifest_file => File::Spec->join($self->_workspace_path,
            'manifest.xml'));
    for my $output_name ($self->_output_file_names) {
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


sub _output_file_names {
    my $self = shift;

    return $self->_property_names(is_output => 1, data_type => 'File');
}

sub _property_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(@_);
}

sub _translate_outputs {
    my ($self, $allocation) = @_;

    for my $output_file_name ($self->_output_file_names) {
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
    my $self = shift;

    return;
}


1;

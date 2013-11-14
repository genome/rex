package Tool::Base;

use strict;
use warnings FATAL => 'all';

use UR;

use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();
use Translator;

#use Checkpoint;


class Tool::Base {
    is => 'Command::V2',
    is_abstract => 1,

    has_optional_transient => [
        _raw_inputs => {
            is => 'HASH',
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

    $self->_cache_and_translate_inputs;

    $self->execute_tool;

    $self->_save_and_translate_outputs;

    return 1;
}

sub _cache_and_translate_inputs {
    my $self = shift;

    $self->_cache_raw_inputs;
    $self->_translate_inputs;

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

    printf("Translating inputs for command: %s\n", $self->class);
    for my $input_name ($self->_input_names) {
        $self->$input_name(Translator::url_to_scalar($self->$input_name));
    }

    return;
}

sub _save_and_translate_outputs {
    my $self = shift;

    return;
}


1;

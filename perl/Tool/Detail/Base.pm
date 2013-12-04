package Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Result;
use Result::Input;
use Result::Output;

use Tool::Detail::AttributeSetter;
use Tool::Detail::Contextual;
with 'WorkflowCompatibility::Role';


has test_name => (
    is => 'rw',
    traits => ['Param', 'Contextual'],
    required => 1,
);

has _process => (
    is => 'rw',
    traits => ['Param', 'Contextual'],
    required => 1,
);

has _step_label => (
    is => 'rw',
    traits => ['Param', 'Contextual'],
    required => 1,
);

sub status_message {
    my $self = shift;
    my $str = shift;

    printf($str . "\n", @_);
    return;
}

sub shortcut {
    my $self = shift;

    $self->status_message('Attempting to shortcut %s with test name (%s)',
        ref $self, $self->test_name);

    my $result = Result->lookup(inputs => $self->_inputs_as_hashref,
        tool_class_name => ref $self, test_name => $self->test_name);

    if ($result) {
        $self->status_message('Found matching result with lookup hash (%s)',
            $result->lookup_hash);
        $self->_set_outputs_from_result($result);

        $self->_create_process_step($result);
        return 1;

    } else {
        $self->status_message('No matching result found for shortcut');
        return;
    }
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

sub _property_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(@_);
}

sub _set_outputs_from_result {
    my ($self, $result) = @_;

    for my $output ($result->outputs) {
        my $name = $output->name;
        $self->$name($output->value_id);
    }

    return;
}

sub _create_process_step {
    my ($self, $result) = @_;

    $self->_translate_inputs('_process', '_step_label');
    ProcessStep->create(process => $self->_process, result => $result,
        label => $self->_step_label);

    return;
}


sub execute {
    my $self = shift;

    die "not implemented yet";
}



sub inputs {
    my $self = shift;

    return map {$_->name} grep {$_->does('Input')}
        $self->meta->get_all_attributes;
}

sub outputs {
    my $self = shift;

    return map {$_->name} grep {$_->does('Output')}
        $self->meta->get_all_attributes;
}

sub params {
    my $self = shift;

    return map {$_->name} grep {$_->does('Param')}
        $self->meta->get_all_attributes;
}

sub contextual_params {
    my $self = shift;

    return map {$_->name} grep {$_->does('Param') && $_->does('Contextual')}
        $self->meta->get_all_attributes;
}

sub non_contextual_params {
    my $self = shift;

    return map {$_->name} grep {$_->does('Param') && !$_->does('Contextual')}
        $self->meta->get_all_attributes;
}


no Tool::Detail::AttributeSetter;
__PACKAGE__->meta->make_immutable;

package Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Log::Log4perl qw();
use Result;
use Result::Input;
use Result::Output;
use Translator;

use Tool::Detail::AttributeSetter;
use Tool::Detail::Contextual;
with 'WorkflowCompatibility::Role';


Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

my $logger = Log::Log4perl->get_logger();


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


sub shortcut {
    my $self = shift;

    $logger->info("Attempting to shortcut ", ref $self,
        " with test name (", $self->test_name, ")");

    my $result = Result->lookup(inputs => $self->_inputs_as_hashref,
        tool_class_name => ref $self, test_name => $self->test_name);

    if ($result) {
        $logger->info("Found matching result with lookup hash (",
            $result->lookup_hash, ")");
        $self->_set_outputs_from_result($result);

        $self->_create_process_step($result);
        return 1;

    } else {
        $logger->info("No matching result found for shortcut");
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

    return $self->_property_names(is_input => 1), $self->non_contextual_params;
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

sub _translate_inputs {
    my $self = shift;

    my $translator = Translator->new();
    for my $input_name (@_) {
        $self->$input_name($translator->resolve_scalar_or_url($self->$input_name));
    }

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

sub non_contextual_params {
    my $self = shift;

    return map {$_->name} grep {$_->does('Param') && !$_->does('Contextual')}
        $self->meta->get_all_attributes;
}


no Tool::Detail::AttributeSetter;
__PACKAGE__->meta->make_immutable;

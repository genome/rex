package WorkflowCompatibility::FakeProperty::Input;
use Moose;
use warnings FATAL => 'all';

extends 'WorkflowCompatibility::FakeProperty';

sub is_input { 1; }

__PACKAGE__->meta->make_immutable;

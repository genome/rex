package WorkflowCompatibility::FakeProperty::Param;
use Moose;
use warnings FATAL => 'all';

extends 'WorkflowCompatibility::FakeProperty';

sub is_param { 1; }

__PACKAGE__->meta->make_immutable;

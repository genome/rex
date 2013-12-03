package Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Tool::Detail::AttributeSetter;
with 'WorkflowCompatibility::Role';


has_param 'test_name';
has_param '_process';
has_param '_step_label';


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


no Tool::Detail::AttributeSetter;
__PACKAGE__->meta->make_immutable;

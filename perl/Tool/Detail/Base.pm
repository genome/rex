package Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Tool::Detail::AttributeSetter;
with 'WorkflowCompatibility::Role';


has_contextual_param 'test_name';
has_contextual_param '_process';
has_contextual_param '_step_label';


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

package TestTool::Base;

use strict;
use warnings FATAL => 'all';

use UR;
use Tool;

class TestTool::Base {
    is => 'Tool::Base',
};


sub shortcut {
    my $self = shift;
    return $self->execute;
}

sub execute {
    my $self = shift;

    $self->make_announcement();
    $self->set_outputs();

    return 1;
}

sub make_announcement {
    my $self = shift;

    printf("Hello from %s\n", $self->class);

    my @output_properties = $self->output_properties;
    printf("Output Properties: %s\n",
        Data::Dumper::Dumper(\@output_properties));
}

sub output_properties {
    my $self = shift;

    return map {$_->property_name} $self->class->__meta__->properties(
        is_output => 1);
}

sub set_outputs {
    my $self = shift;

    for my $output_name ($self->output_properties) {
        $self->$output_name(sprintf("out:%s", $output_name));
    }
}



1;


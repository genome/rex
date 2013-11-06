package Tool::Base;

use strict;
use warnings FATAL => 'all';

use UR;

class Tool::Base {
    is => 'Command::V2',
};


sub shortcut {
    my $self = shift;
    return $self->execute;
}

sub execute {
    my $self = shift;

    printf("Hello from %s\n", $self->class);
    my @stuff = $self->output_properties;
    printf("I haz output properteez: %s\n", Data::Dumper::Dumper(
            \@stuff));

    for my $output_name ($self->output_properties) {
        $self->$output_name(sprintf("out:%s", $output_name));
    }

    return 1;
}

sub output_properties {
    my $self = shift;
    return map {$_->property_name} $self->class->__meta__->properties(
        is_output => 1);
}


1;

package Translator::GMS::Object;

use Moose;
use warnings FATAL => 'all';


sub type {
    die 'abstract';
}

sub class_name {
    die 'abstract';
}

sub resolve {
    my ($self, $url) = @_;

    my %query = $url->query_form;

    my $class_name = $self->class_name;
    my $force_scalar = $class_name->get(%query);
    return $force_scalar;
}

1;

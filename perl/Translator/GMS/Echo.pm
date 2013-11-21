package Translator::GMS::Echo;

use Moose;
use warnings FATAL => 'all';

sub type {
    return 'echo';
}

sub resolve {
    my ($self, $url) = @_;

    my ($junk, $type, @args) = $url->path_components;
    return File::Spec->join('', @args);
}

1;

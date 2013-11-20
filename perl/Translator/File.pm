package Translator::File;

use Moose;
use warnings FATAL => 'all';

sub scheme {
    return 'file';
}

sub resolve {
    my $class = shift;
    my $url = shift;

    return $url->path;
}

1;

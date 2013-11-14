package Translator::File;

use strict;
use warnings FATAL => 'all';

use UR;


class Translator::File {};


sub fetch {
    my ($class, $url) = @_;

    return $url->path;
}

1;

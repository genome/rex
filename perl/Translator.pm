package Translator;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use URI::URL qw();


sub url_to_scalar {
    my $string = shift;

    my $url = new URI::URL $string;

    if ($url->scheme) {
        return dispatch_url($url);
    } else {
        return $string;
    }
}


use Translator::File;
use Translator::GMS;
my %_SCHEME_MAP = (
    file => 'Translator::File',
    gms => 'Translator::GMS',
);
sub dispatch_url {
    my $url = shift;

    unless ($url->scheme) {
        confess sprintf("No scheme specified in '%s'", $url);
    }

    my $fetcher_class_name = $_SCHEME_MAP{$url->scheme};
    unless ($fetcher_class_name) {
        confess sprintf(
            "Could not retrieve data for url '%s', no fetcher for scheme",
            $url);
    }

#    require $fetcher_class_name;
    return $fetcher_class_name->fetch($url);
}


1;

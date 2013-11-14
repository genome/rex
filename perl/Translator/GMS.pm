package Translator::GMS;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use File::Spec qw();
use Manifest::Reader;


class Translator::GMS {};


sub fetch {
    my ($class, $url) = @_;

    if ($url->netloc) {
        confess sprintf(
            "Currently only local data are supported, but host specified: %s",
            $url->netloc);
    }

    my ($type, $args) = _split_path($url->path);
    return $class->$type($args)
}

sub _split_path {
    my $path = shift;
    my @components = File::Spec->splitdir($path);

    shift @components;  # Remove empty string

    my $type = shift @components;
    return $type, \@components;
}

sub echo {
    my ($class, $args) = @_;
    return File::Spec->join('', @$args);
}

sub data {
    my ($class, $args) = @_;

    my ($allocation_id, $tag) = @$args;

    my $allocation = Genome::Disk::Allocation->get(id => $allocation_id);
    my $reader = Manifest::Reader->create(
        manifest_file => File::Spec->join($allocation->absolute_path,
            'manifest.xml'));
    return $reader->path_to($tag);
}


1;

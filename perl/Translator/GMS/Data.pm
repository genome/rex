package Translator::GMS::Data;

use Moose;
use warnings FATAL => 'all';
use File::Spec;
use Manifest::Reader;

sub type {
    return 'data';
}

sub resolve {
    my ($self, $url) = @_;

    my $allocation_id = _extract_allocation_id($url);
    my %query_form = $url->query_form;
    my $tag = $query_form{tag};

    my $allocation = Genome::Disk::Allocation->get(id => $allocation_id);
    my $reader = Manifest::Reader->create(
        manifest_file => File::Spec->join($allocation->absolute_path,
            'manifest.xml'));
    return $reader->path_to($tag);
}

sub _extract_allocation_id {
    my $url = shift;

    my ($junk, $type, $allocation_id) = $url->path_components;

    return $allocation_id;
}

1;

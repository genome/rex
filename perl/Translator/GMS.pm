package Translator::GMS;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Spec qw();
use Manifest::Reader;
use Process;

sub scheme {
    return 'gms';
}

sub resolve {
    my ($self, $url) = @_;

    if ($url->netloc) {
        confess sprintf(
            "Currently only local data are supported, but host specified: %s",
            $url->netloc);
    }

    my $type = _extract_type($url);
    return $self->$type($url)
}

sub _extract_type {
    my $url = shift;
    my ($type, $rest) = _split_path($url->path);
    return $type;
}

sub _split_path {
    my $path = shift;
    my @components = File::Spec->splitdir($path);

    shift @components;  # Remove empty string

    my $type = shift @components;
    return $type, \@components;
}

sub echo {
    my ($self, $url) = @_;
    my ($type, $args) = _split_path($url->path);
    return File::Spec->join('', @$args);
}

sub data {
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

    my ($type, $rest) = _split_path($url->path);

    return $rest->[0];
}

sub process {
    my ($self, $url) = @_;

    my $process_id = _extract_process_id($url);
    return Process->get(id => $process_id);
}

sub _extract_process_id {
    my $url = shift;

    my ($type, $rest) = _split_path($url->path);

    return $rest->[0];
}


1;

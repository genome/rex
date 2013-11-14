package Manifest::Reader;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use File::Basename qw();
use File::Spec qw();

use Manifest::Detail::ReaderWriterBase;
use XML::LibXML qw();


class Manifest::Reader {
    is => 'Manifest::Detail::ReaderWriterBase',

    has => [
        manifest_file => {
            is => 'Path',
        },
    ],

};


sub path_to {
    my ($self, $tag) = @_;

    my $nodes = $self->document->findnodes(
        sprintf('manifest/file[@tag="%s"]', $tag));

    unless (scalar(@$nodes) == 1) {
        confess sprintf(
            "Didn't find exactly one node for tag '%s' in manifest file '%s'",
            $tag, $self->manifest_file);
    }

    return File::Spec->join($self->base_path,
        $nodes->[0]->getAttribute('path'));
}

sub total_kilobytes {
    my $self = shift;

    my $total = 0;
    for my $entry ($self->entries) {
        $total += $entry->{'kilobytes'};
    }
    return $total;
}

sub entries {
    my $self = shift;

    my $nodes = $self->document->findnodes('manifest/file');
    my @entries;
    for my $node (@$nodes) {
        my %entry;
        for my $attr ($node->attributes) {
            $entry{$attr->name} = $attr->value;
        }
        push @entries, \%entry;
    }
    return @entries;
}

sub document {
    my $self = shift;

    return $self->parser->parse_file($self->manifest_file);
}
Memoize::memoize('document');


1;

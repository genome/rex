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

    has_transient_optional => [
        _document => {
        },
        _parser => {
            is => 'XML::LibXML',
        },
    ],
};


sub path_to {
    my ($self, $tag) = @_;

    my $nodes = $self->document->findnodes(
        sprintf('//file[@tag="%s"]', $tag));

    unless (scalar(@$nodes) == 1) {
        confess sprintf(
            "Didn't find exactly one node for tag '%s' in manifest file '%s'",
            $tag, $self->manifest_file);
    }

    return $nodes->[0]->getAttribute('path');
}


sub base_path {
    my $self = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse(
        $self->manifest_file);

    return $path;
}

sub document {
    my $self = shift;

    unless ($self->_document) {
        $self->_document($self->parser->parse_file($self->manifest_file));
    }

    return $self->_document;
}

sub parser {
    my $self = shift;

    unless ($self->_parser) {
        $self->_parser(XML::LibXML->new);
    }

    return $self->_parser;
}


1;

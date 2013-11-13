package Manifest;

use strict;
use warnings FATAL => 'all';

use UR;
use File::Basename qw();
use File::Spec qw();

use XML::LibXML qw();


class Manifest {
    id_generator => '-uuid',

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
        _schema => {
            is => 'XML::LibXML::Schema',
        },
    ],
};


sub validate {
    my $self = shift;

    $self->schema->validate($self->document);

    return;
}

sub path_to {
    my ($self, $tag) = @_;

    return $tag;
}


sub base_path {
    my $self = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse(
        $self->manifest_file);

    return $path;
}

sub schema_path {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__);

    return File::Spec->join($path, 'manifest.xsd');
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

sub schema {
    my $self = shift;

    unless ($self->_schema) {
        $self->_schema(XML::LibXML::Schema->new(
                location => schema_path()));
    }

    return $self->_schema;
}


1;

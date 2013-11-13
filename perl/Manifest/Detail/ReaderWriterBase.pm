package Manifest::Detail::ReaderWriterBase;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use XML::LibXML qw();


class Manifest::Detail::ReaderWriterBase {
    id_generator => '-uuid',
    is_abstract => 1,

    has_transient_optional => [
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

sub schema {
    my $self = shift;

    unless ($self->_schema) {
        $self->_schema(XML::LibXML::Schema->new(
                location => schema_path()));
    }

    return $self->_schema;
}

sub schema_path {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__);

    return File::Spec->rel2abs(File::Spec->join($path, 'manifest.xsd'));
}


1;

package Manifest::Writer;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use Manifest::Detail::ReaderWriterBase;
use XML::LibXML qw();
use Params::Validate qw();


class Manifest::Writer {
    is => 'Manifest::Detail::ReaderWriterBase',

    has => [
        manifest_file => {
            is => 'Path',
        },
    ],

    has_transient_optional => [
        _document => {
        },
    ],
};


sub add_file {
    my $self = shift;
    my %params = Params::Validate::validate(@_,
        {
            path => { type => Params::Validate::SCALAR },
            tag => { type => Params::Validate::SCALAR },
        });

    my $element = $self->document->createElement('file');
    $element->setAttribute('path', $params{path});
    $element->setAttribute('tag', $params{tag});

    $self->root->appendChild($element);

    return;
}


sub save {
    my $self = shift;

    $self->validate;
    $self->document->toFile($self->manifest_file, 1);

    return;
}


sub root {
    my $self = shift;

    return $self->document->documentElement;
}

sub document {
    my $self = shift;

    unless ($self->_document) {
        $self->_document(XML::LibXML::Document->new);

        my $root = $self->_document->createElement('manifest');
        $self->_document->setDocumentElement($root);
    }

    return $self->_document;
}


1;

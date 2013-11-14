package Manifest::Detail::ReaderWriterBase;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use XML::LibXML qw();
use Memoize qw();
use File::Spec qw();


class Manifest::Detail::ReaderWriterBase {
    id_generator => '-uuid',
    is_abstract => 1,
};


sub validate {
    my $self = shift;

    # Re-construct the doc to avoid an apparent bug in XML::LibXML validation
    my $doc_to_validate = $self->parser->parse_string(
        $self->document->toString);

    $self->schema->validate($doc_to_validate);

    return;
}

sub schema {
    my $self = shift;
    return XML::LibXML::Schema->new(location => schema_path());
}
Memoize::memoize('schema');

sub schema_path {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__);

    return File::Spec->rel2abs(File::Spec->join($path, 'manifest.xsd'));
}


sub base_path {
    my $self = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse(
        $self->manifest_file);

    return $path;
}

sub parser {
    my $self = shift;

    return XML::LibXML->new;
}


1;

package Tool;
use Moose qw();
use warnings FATAL => 'all';

use Moose::Exporter;
use Tool::Detail::AttributeSetter;


Moose::Exporter->setup_import_methods(
    also => ['Moose', 'Tool::Detail::AttributeSetter'],
);


sub init_meta {
    shift;
    return Moose->init_meta(@_, base_class => 'Tool::Detail::Base');
}


1;

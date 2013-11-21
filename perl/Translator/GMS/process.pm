package Translator::GMS::Process;

use Moose;
use warnings FATAL => 'all';
use Process;

extends 'Translator::GMS::Object';


sub type {
    die 'process';
}

sub class_name {
    return 'Process';
}

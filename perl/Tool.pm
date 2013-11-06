package Tool;

use strict;
use warnings FATAL => 'all';

use UR;


UR::Object::Type->define(
    class_name => 'Tool',
    is => ['UR::Namespace'],
    english_name => 'tool',
);


1;

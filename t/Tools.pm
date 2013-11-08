package Tools;

use strict;
use warnings FATAL => 'all';

use UR;

UR::Object::Type->define(
    class_name => 'Tools',
    is => ['UR::Namespace'],
    english_name => 'tools',
);

1;

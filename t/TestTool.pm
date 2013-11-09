package TestTool;

use strict;
use warnings FATAL => 'all';

use UR;

UR::Object::Type->define(
    class_name => 'TestTool',
    is => ['UR::Namespace'],
    english_name => 'test-tool',
);

1;

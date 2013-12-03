package Compiler::TestTool;

use strict;
use warnings FATAL => 'all';

use UR;

UR::Object::Type->define(
    class_name => 'Compiler::TestTool',
    is => ['UR::Namespace'],
    english_name => 'test-tool',
);

1;

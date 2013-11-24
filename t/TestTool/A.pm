package TestTool::A;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::A {
    is => 'TestTool::Base',

    has_input => [
        ai1 => {
            dsl_tags => ['T1'],
        },
    ],

    has_output => [
        ao1 => {
            dsl_tags => ['T6'],
        },
    ],
};


1;

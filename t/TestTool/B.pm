package TestTool::B;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::B {
    is => 'TestTool::Base',

    has_input => [
        bi1 => {
            dsl_tags => ['T4'],
        },
        bi2 => {
            dsl_tags => ['T5'],
        },
        bi3 => {
            dsl_tags => ['T6'],
        },
    ],

    has_output => [
        bo1 => {
            dsl_tags => ['T7'],
        },
    ],
};


1;

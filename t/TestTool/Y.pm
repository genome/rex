package TestTool::Y;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::Y {
    is => 'TestTool::Base',

    has_input => [
        y_in_1 => {
            dsl_tags => ['X::Output1'],
        },
        y_in_2 => {
            dsl_tags => ['X::Output1'],
        },
    ],

    has_output => [
        y_out_1 => {
            dsl_tags => ['Y::Output1'],
        },
    ],
};


1;

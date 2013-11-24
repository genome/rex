package TestTool::X;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::X {
    is => 'TestTool::Base',

    has_input => [
        x_in_1 => {
            dsl_tags => ['X::Input1'],
        },
    ],

    has_output => [
        x_out_1 => {
            dsl_tags => ['X::Output1'],
        },
    ],
};


1;

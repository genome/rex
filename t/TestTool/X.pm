package TestTool::X;

use strict;
use warnings FATAL => 'all';

use UR;

class TestTool::X {
    is => 'TestTool::Base',

    has_input => [
        x_in_1 => {},
    ],

    has_output => [
        x_out_1 => {},
    ],
};


1;

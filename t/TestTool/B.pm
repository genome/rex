package TestTool::B;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::B {
    is => 'TestTool::Base',

    has_input => [
        bi1 => {},
        bi2 => {},
        bi3 => {},
    ],

    has_output => [
        bo1 => {},
    ],
};


1;

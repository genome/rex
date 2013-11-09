package TestTool::F;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::F {
    is => 'TestTool::Base',

    has_input => [
        fi1 => {},
    ],

    has_output => [
        fo1 => {},
    ],
};


1;

package TestTool::F1;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::F1 {
    is => 'TestTool::Base',

    has_input => [
        input_1 => {
            dsl_tags => ['Alpha', 'Beta'],
        },
        input_2 => {
            dsl_tags => ['Alpha', 'Beta'],
        },
    ],

    has_output => [
        output_1 => {
            dsl_tags => ['Alpha', 'Beta', 'Gamma'],
        },
        output_2 => {
            dsl_tags => ['Alpha', 'Beta'],
        },
        output_3 => {
            dsl_tags => ['Alpha', 'Gamma'],
        },
    ],
};


1;

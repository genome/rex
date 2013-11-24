package TestTool::M1;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::M1 {
    is => 'TestTool::Base',

    has_input => [
        input_1 => {
            dsl_tags => ['Alpha', 'Beta'],
        },
    ],

    has_output => [
        output_1 => {
            dsl_tags => ['Alpha', 'Gamma'],
        },
        output_2 => {
            dsl_tags => ['Beta', 'Gamma'],
        },
        output_3 => {
            dsl_tags => ['Alpha', 'Beta', 'Gamma'],
        },
    ],
};


1;

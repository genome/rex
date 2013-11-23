package TestTool::Example;

use strict;
use warnings FATAL => 'all';

use UR;
use TestTool::Base;

class TestTool::Example {
    is => 'TestTool::Base',

    has_input => [
        input_1 => {
            dsl_type => 'Alpha',
        },
        input_2 => {
            dsl_type => 'Alpha',
        },
        input_3 => {
            dsl_type => 'Beta',
        },
    ],

    has_output => [
        output_1 => {
            dsl_type => 'Alpha',
        },
        output_2 => {
            dsl_type => 'Alpha',
        },
        output_3 => {
            dsl_type => 'Beta',
        },
    ],
};


1;

package Compiler::TestTool::Example;

use strict;
use warnings FATAL => 'all';

use UR;
use Compiler::TestTool::Base;

class Compiler::TestTool::Example {
    is => 'Compiler::TestTool::Base',

    has_input => [
        input_1 => {
            dsl_tags => ['Alpha'],
        },
        input_2 => {
            dsl_tags => ['Alpha'],
        },
        input_3 => {
            dsl_tags => ['Beta'],
        },
    ],

    has_output => [
        output_1 => {
            dsl_tags => ['Alpha'],
        },
        output_2 => {
            dsl_tags => ['Alpha'],
        },
        output_3 => {
            dsl_tags => ['Beta'],
        },
    ],
};


1;

package Tools::X;

use strict;
use warnings FATAL => 'all';

use UR;
use Tools::Base;

class Tools::X {
    is => 'Tools::Base',

    has_input => [
        x_in_1 => {},
    ],

    has_output => [
        x_out_1 => {},
    ],
};


1;

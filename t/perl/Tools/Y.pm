package Tools::Y;

use strict;
use warnings FATAL => 'all';

use UR;
use Tools::Base;

class Tools::Y {
    is => 'Tools::Base',

    has_input => [
        y_in_1 => {},
        y_in_2 => {},
    ],

    has_output => [
        y_out_1 => {},
    ],
};


1;

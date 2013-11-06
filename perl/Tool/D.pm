package Tool::D;

use strict;
use warnings FATAL => 'all';

use UR;
use Tool::Base;

class Tool::D {
    is => 'Tool::Base',

    has_input => [
        di1 => {},
    ],

    has_output => [
        do1 => {},
    ],
};


1;

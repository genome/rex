package Tool::B;

use strict;
use warnings FATAL => 'all';

use UR;

class Tool::B {
    is => 'Tool::Base',

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

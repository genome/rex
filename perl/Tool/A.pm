package Tool::A;

use strict;
use warnings FATAL => 'all';

use UR;
use Tool::Base;

class Tool::A {
    is => 'Tool::Base',

    has_input => [
        ai1 => {},
    ],

    has_output => [
        ao1 => {},
    ],
};


1;

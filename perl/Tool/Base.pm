package Tool::Base;

use strict;
use warnings FATAL => 'all';

use UR;


class Tool::Base {
    is => 'Command::V2',
    is_abstract => 1,
};


sub execute {
    my $self = shift;

    $self->execute_tool;

    return 1;
}


1;

package Tool::Base;

use strict;
use warnings FATAL => 'all';

use UR;

class Tool::Base {
    is => 'Command::V2',
};


sub shortcut {
    my $self = shift;
    return $self->execute;
}

sub execute {
    my $self = shift;

    printf("Hello from %s\n", $self->class);
    return 1;
}


1;

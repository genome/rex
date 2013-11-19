package CLI::Process::Link;

use strict;
use warnings FATAL => 'all';

use UR;

use Process;
use Cwd qw();


class CLI::Process::Link {
    is => 'Command::V2',

    has => [
        process => {
            is => 'Process',
            shell_args_position => 1,
        },

        target => {
            is => 'Directory',
            shell_args_position => 2,
        },
    ],
};


sub execute {
    my $self = shift;

    my $process = Process->get(id => $self->process);

    for my $step ($process->steps) {
        $step->link($self->_target_absolute_path);
    }

    return 1;
}

sub _target_absolute_path {
    my $self = shift;

    return Cwd::realpath($self->target);
}


1;

package Rex::CLI::Process::View;

use strict;
use warnings;

use Genome;
use Amber::Process;

class Rex::CLI::Process::View {
    is => [
        'Genome::Command::Viewer',
        'Genome::Command::WorkflowMixin',
    ],
    has => [
        process => {
            is => 'Amber::Process',
            shell_args_position => 1,
            doc => 'Process you want to view',
        },
        workflow => {
            is => 'Boolean',
            is_optional => 1,
            default_value => 1,
            doc => 'Display workflow.',
        },
    ],
};

sub help_synopsis {
    return <<EOP;
    Displays basic information about a process.
EOP
}

sub help_detail {
    return <<EOP;
Displays information about a process and its workflow.

    process view <process_id>

EOP
}

sub write_report {
    my ($self, $width, $handle) = @_;

    my $process = Amber::Process->get(id => $self->process);
    $self->_display_process($handle, $process);

    if($self->workflow) {
        my $workflow = $process->workflow_instance;
        $self->_display_workflow($handle, $workflow);
    }

    1;
}

sub _display_process {
    my ($self, $handle, $process) = @_;

    my $format_str = <<EOS;
%s
%s %s
%s


EOS
    print $handle sprintf($format_str,
        $self->_color_heading('Process'),
        $self->_color_pair('ID',
            $self->_pad_right($process->id, $self->COLUMN_WIDTH)),
        $self->_color_pair('Status',
            $self->_status_color($process->status)),
        $self->_color_pair('MetaData Directory', $process->allocation->absolute_path),
    );
}

1;

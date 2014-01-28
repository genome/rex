package Rex::CLI::Process::View;

use strict;
use warnings;

use Genome;
use Workflow;
use Procera::Persistence::Amber;

class Rex::CLI::Process::View {
    is => [
        'Genome::Command::Viewer',
        'Genome::Command::WorkflowMixin',
    ],
    has => [
        process => {
            is => 'Text',
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

    my $process_info = _get_process_info($self->process);

    $self->_display_process_info($handle, $process_info);

    if($self->workflow) {
        my $workflow = _workflow_instance($process_info->{workflow_name});
        $self->_display_workflow($handle, $workflow);
    }

    1;
}

sub _get_process_info {
    my $process = shift;

    my $amber = Procera::Persistence::Amber->new();
    my $process_info = eval {$amber->get_process($process)};
    unless(defined $process_info) {
        die sprintf("Couldn't find process (%s) in Amber (%s)",
            $process, $amber->base_url);
    }
    return $process_info;
}

sub _display_process_info {
    my ($self, $handle, $process_info) = @_;

    my $allocation = Genome::Disk::Allocation->get(
        id => $process_info->{allocation_id},
    );

    my $format_str = <<EOS;
%s
%s
%s


EOS
    print $handle sprintf($format_str,
        $self->_color_heading('Process'),
        $self->_color_pair('ID',
            $self->_pad_right($process_info->{id}, $self->COLUMN_WIDTH)),
        $self->_color_pair('MetaData Directory', $allocation->absolute_path),
    );
}

sub _workflow_instance {
    my $name = shift;

    my $force_scalar = Workflow::Operation::Instance->get(
        name => $name,
    );
    return $force_scalar;
}

1;

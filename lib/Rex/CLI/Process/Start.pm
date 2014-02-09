package Rex::CLI::Process::Start;

use Moose;
use warnings FATAL => 'all';

use Procera::Compiler;
use Procera::Runner;
use Procera::SourceFile qw(file_path);

use File::Spec qw();
use File::Temp qw(tempdir);

with 'MooseX::Getopt';

has 'source_path' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    required => 1,
    cmd_flag => 's',
    cmd_aliases => ['source-path'],
    documentation => 'TOOL::OR::PROCESS',
);

has 'inputs_files' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
    cmd_flag => 'i',
    cmd_aliases => ['inputs-file'],
    documentation => 'A tab-delimited inputs-file',
);

has _workflow_file => (
    is => 'rw',
    isa => 'Str',
);

has _inputs_file => (
    is => 'rw',
    isa => 'Str',
);

sub run {
    my $self = shift;

    $self->compile();
    $self->run_process();
}


sub compile {
    my $self = shift;

    my $tempdir = tempdir(CLEANUP => 1);
    my $compiler = Procera::Compiler->new(
        'input-file' => file_path($self->source_path),
        'output-directory' => $tempdir,
    );
    $compiler->execute;

    $self->_workflow_file($compiler->workflow_file);
    $self->_inputs_file($compiler->inputs_file);

    return;
}

sub run_process {
    my $self = shift;

    my $runner = Procera::Runner->new(
        workflow => $self->_workflow_file,
        inputs => [$self->_inputs_file, @{$self->inputs_files}],
        process_name => $self->source_path,
    );
    $runner->execute;

    return;
}

1;

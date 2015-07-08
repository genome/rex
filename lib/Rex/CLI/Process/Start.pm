package Rex::CLI::Process::Start;

use Moose;
use warnings FATAL => 'all';

use Procera::Compiler;
use Procera::Runner;
use Procera::SourceFile qw(file_path);
use Procera::Factory::Storage;
use Procera::Factory::Persistence;
use Log::Log4perl qw();

Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

use Data::Dump qw(pp);
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
has 'run_local_and_wait' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    cmd_flag => 'l',
    cmd_aliases => ['run-local-and-wait'],
    documentation => 'Runs the process locally (using tmp storage) and waits at the end.',
);

has _outputs => (
    is => 'rw',
    isa => 'HashRef',
);

has _runner => (
    is => 'rw',
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

    $self->setup_environment();

    $self->compile();
    $self->run_process();

    $self->announce_outputs();
    if ($self->run_local_and_wait) {
        print "\nYou've set the flag to wait after processing... press enter to finish (will clean up all temporary files)\n";
        <STDIN>;
    }
}

sub announce_outputs {
    my $self = shift;

    my $storage = Procera::Factory::Storage::create($self->_runner->_storage_type);
    my $persistence = Procera::Factory::Persistence::create($self->_runner->_persistence_type);
    my $translator = Procera::Translator->new(
        storage => $storage,
        persistence => $persistence,
    );
    for my $output_name (keys %{$self->_outputs}) {
        no warnings;
        my $translated_output;
        if (ref($self->_outputs->{$output_name}) eq 'ARRAY') {
            $translated_output = [map {$translator->resolve_scalar_or_url($_)}
                @{$self->_outputs->{$output_name}}];
        }
        else {
            $translated_output = $translator->resolve_scalar_or_url(
                $self->_outputs->{$output_name});
        }

        printf "%s is %s\n", $output_name, pp($translated_output);
    }
    return;
}

sub setup_environment {
    my $self = shift;

    if ($self->run_local_and_wait) {
        $ENV{UR_DBI_NO_COMMIT} = 1;
        $ENV{NO_LSF} = 1;
        delete $ENV{WF_USE_FLOW};
        delete $ENV{AMBER_URL};
        delete $ENV{ALLOCATION_URL};
    }
    return;
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
    $self->_runner($runner);
    $self->_outputs($runner->execute);

    return;
}

1;

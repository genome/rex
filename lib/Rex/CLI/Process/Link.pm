package Rex::CLI::Process::Link;

use Moose;
use warnings FATAL => 'all';

use Procera::Translator;
use Procera::Factory::Storage;
use Procera::Factory::Persistence;

with 'MooseX::Getopt';

has 'process' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    required => 1,
    cmd_flag => 'p',
    cmd_aliases => ['process'],
    documentation => 'process url e.g. /v1/processes/12/',
);

has 'target' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    required => 1,
    cmd_flag => 't',
    cmd_aliases => ['target'],
    documentation => 'directory (will be created if non-existent)',
);

has _persistence => (
    is => 'rw',
    builder => '_build_persistence',
);
has _storage => (
    is => 'rw',
    builder => '_build_storage',
);

sub run {
    my $self = shift;

    my $translator = Procera::Translator->new(
        storage => $self->_storage,
        persistence => $self->_persistence,
    );

    for my $step_info (@{$self->process_steps}) {
        my %outputs = %{$self->_get_step_outputs($step_info)};
        for my $name (keys %outputs) {
            my $value = $translator->resolve_scalar_or_url($outputs{$name});
            if (-f $value) {
                _make_symlink($value,
                    $self->_get_destination($step_info->{label}));
            }
        }
    }
}

sub _get_destination {
    my ($self, $label) = @_;

    return File::Spec->join($self->target, split(/\./, $label));
}

sub _get_step_outputs {
    my ($self, $step_info) = @_;

    my $result_info = $self->_get_result($step_info->{result});
    return $result_info->{outputs};
}

sub _get_result {
    my ($self, $url) = @_;

    return $self->_persistence->get_process($url);
}

sub process_steps {
    my $self = shift;

    my $process_info = eval {$self->_persistence->get_process($self->process)};
    unless(defined $process_info) {
        die sprintf("Couldn't find process (%s) in persistence (%s)",
            $self->process, $self->_persistence->base_url);
    }

    return $self->_persistence->get_process_steps($process_info->{id});
}

sub _make_symlink {
    my ($source, $destination) = @_;

    File::Path::make_path($destination);
    my ($file) = File::Basename::fileparse($source);
    symlink $source, File::Spec->join($destination, $file);

    return;
}

sub _build_persistence {
    return Procera::Factory::Persistence::create('amber');
}

sub _build_storage {
    return Procera::Factory::Storage::create('allocation');
}

1;

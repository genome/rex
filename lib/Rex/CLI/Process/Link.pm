package Rex::CLI::Process::Link;

use Moose;
use warnings FATAL => 'all';

use Procera::Translator;
use Procera::Factory::Storage;
use Procera::Factory::Persistence;
use Params::Validate qw(validate_pos :types);
use Log::Log4perl qw();

Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

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

has 'step_regexes' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'ArrayRef',
    cmd_flag => 's',
    cmd_aliases => ['step-regex'],
    documentation => 'only link steps with labels matching this regex (repeatable)',
    predicate => 'has_step_regexes',
);

has 'exclude_parallel_steps' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    cmd_flag => 'e',
    default => 0,
    cmd_aliases => ['exclude-parallelized-steps'],
    documentation => 'do not link steps that were parallelized',
);

has _persistence => (
    is => 'rw',
    builder => '_build_persistence',
);
has _storage => (
    is => 'rw',
    builder => '_build_storage',
);
has _symlinked_anything => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


sub run {
    my $self = shift;

    my $outputs = $self->get_outputs();
    $self->make_symlinks($outputs);
    if ($self->_symlinked_anything) {
        printf "\nResults for process (%s) are symlinked to (%s).\n", $self->process, $self->target;
    } else {
        printf "\nNo results for process (%s) were found matching your options.\n", $self->process, $self->target;
    }
}


sub _get_destination {
    my ($self, $step_info) = @_;

    return File::Spec->join($self->target, split(/\./, $step_info->{label}));
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

sub _make_symlink {
    my ($self, $source, $destination) = @_;

    File::Path::make_path($destination);
    my ($file) = File::Basename::fileparse($source);
    symlink $source, File::Spec->join($destination, $file);
    $self->_symlinked_anything(1);

    return;
}

sub _build_persistence {
    return Procera::Factory::Persistence::create('amber');
}

sub _build_storage {
    return Procera::Factory::Storage::create('allocation');
}


sub get_outputs {
    my $self = shift;
    my $translator = Procera::Translator->new(
        storage => $self->_storage,
        persistence => $self->_persistence,
    );

    $| = 1;
    printf "Finding results for process (%s)\n.", $self->process;
    my %outputs;
    my $iter = $self->process_steps_iterator;
    while (my $step_info = $iter->next()) {
        print ".";
        next unless $self->valid_step($step_info->{label});

        my $destination = $self->_get_destination($step_info);
        my $step_id = $step_info->{id};
        my %step_outputs = %{$self->_get_step_outputs($step_info)};
        for my $orig (values %step_outputs) {
            if (ref $orig eq 'ARRAY') {
                my @values = map {$translator->resolve_scalar_or_url($_)} @$orig;
                push @{$outputs{$destination}{$step_id}}, @values;
            } else {
                my $value = $translator->resolve_scalar_or_url($orig);
                push @{$outputs{$destination}{$step_id}}, $value;
            }
        }
    }
    return \%outputs;
}

sub valid_step {
    my ($self, $step_label) = validate_pos(@_, 1, {type => SCALAR});

    if ($self->has_step_regexes) {
        for my $regex (@{$self->step_regexes}) {
            if ($step_label =~ m/$regex/) {
                return 1;
            }
        }
        return 0;
    } else {
        return 1;
    }
}

sub process_steps_iterator {
    my $self = shift;

    my $process_info = eval {$self->_persistence->get_process($self->process)};
    unless(defined $process_info) {
        die sprintf("Couldn't find process (%s) in persistence (%s)\n",
            $self->process, $self->_persistence->base_url);
    }

    return $self->_persistence->get_process_steps_iterator($process_info->{id});
}

sub make_symlinks {
    my ($self, $outputs) = validate_pos(@_, {type => OBJECT}, {type => HASHREF});
    my %outputs = %$outputs;

    for my $destination (sort keys %outputs) {
        if (scalar(keys %{$outputs{$destination}}) > 1) {
            next if $self->exclude_parallel_steps;
            my $count = 1;
            for my $step_id (sort keys %{$outputs{$destination}}) {
                for my $value (@{$outputs{$destination}{$step_id}}) {
                    my $final_destination = File::Spec->join($destination, $count);
                    next if $value =~ /\n/;
                    if (-f $value) {
                        $self->_make_symlink($value, $final_destination);
                    }
                }
                $count += 1;
            }
        } else {
            my @values = @{(values %{$outputs{$destination}})[0]};

            for my $value (@values) {
                next if $value =~ /\n/;
                if (-f $value) {
                    $self->_make_symlink($value, $destination);
                }
            }
        }
    }
}

1;

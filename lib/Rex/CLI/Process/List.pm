package Rex::CLI::Process::List;

use Moose;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos :types);
use Procera::Factory::Persistence;
use Log::Log4perl qw();

Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

with 'MooseX::Getopt';
with 'Rex::CLI::Color';
with 'Rex::CLI::Text';

has 'run_by' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    cmd_flag => 'r',
    cmd_aliases => ['run_by', 'run-by'],
    documentation => "Only show Processes that were run by the specified user(s).",
    predicate => 'has_run_by',
);
has 'started_before' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    cmd_flag => 'b',
    cmd_aliases => ['before'],
    documentation => 'Only show Processes that started on or before (inclusive) '.
            'the specified date.  Similar to "after", "ended-after", and '.
            '"ended-before".  YYYY-MM-DD[ HH:MM[:ss][TZ]] ',
    predicate => 'has_started_before',
);
has 'started_after' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    cmd_flag => 'a',
    cmd_aliases => ['after'],
    predicate => 'has_started_after',
);
has 'ended_before' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    cmd_aliases => ['ended-before'],
    predicate => 'has_ended_before',
);
has 'ended_after' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    cmd_aliases => ['ended-after'],
    predicate => 'has_ended_after',
);
has 'statuses' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    cmd_flag => 't',
    cmd_aliases => ['status'],
    documentation => "Only show Processes that have the specified status(es). ".
            "(must be one of ['running', 'crashed', 'succeeded'])",
    predicate => 'has_statuses',
);
has 'source_paths' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'ArrayRef[Str]',
    cmd_flag => 's',
    cmd_aliases => ['source_path', 'source-path'],
    documentation => "Filter to only show Processes with the specified ".
            "source-path(s) (e.g. Vcf::CrossSample::Indel)",
    predicate => 'has_source_paths',
);

has _persistence => (
    is => 'rw',
    builder => '_build_persistence',
);

sub _build_persistence {
    return Procera::Factory::Persistence::create('amber');
}

sub run {
    my $self = shift;

    my $processes_iter = $self->_persistence->get_processes_iterator(
        sprintf('/v1/processes/?%s', $self->query),
    );

    my $count = 0;
    my %status_counts;
    while (my $info = $processes_iter->next()) {
        if ($count == 0) {
            printf "%s%s%s%s%s%s\n",
                justify($self->color('URI', 'bold'), 'left', 21),
                justify($self->color('Run By', 'bold'), 'left', 10),
                justify($self->color('Started', 'bold'), 'left', 33),
                justify($self->color('Ended', 'bold'), 'left', 33),
                justify($self->color('Status', 'bold'), 'left', 11),
                justify($self->color('Source Path', 'bold'), 'left', 10);
        }
        $count++;

        my $date_started = $info->{date_started};
        my $date_ended = $info->{date_ended};
        if ($date_ended eq $date_started) {
            $date_ended = ' ';
        }
        $status_counts{$info->{status}}++;
        my $status = $self->color_status($info->{status});

        printf "%s%s%s%s%s%s\n",
            justify($info->{resource_uri}, 'left', 21),
            justify($info->{username}, 'left', 10),
            justify($date_started, 'left', 33),
            justify($date_ended, 'left', 33),
            justify($status, 'left', 11),
            justify($info->{source_path}, 'left', 10);
    }

    if ($count == 0) {
        printf "No results were found\n";
        return;
    } else {
        printf "Total: %d  %s\n", $count, 
            join('  ', map {sprintf("%s: %d", $self->color_status($_),
                        $status_counts{$_})} sort keys %status_counts);
    }
}

sub query {
    my $self = shift;

    my @parts = (
        $self->run_by_query,
        $self->before_query,
        $self->after_query,
        $self->ended_before_query,
        $self->ended_after_query,
        $self->status_query,
        $self->source_path_query,
    );
    return join(';', @parts);
}

sub run_by_query {
    my $self = shift;
    return unless $self->has_run_by;

    my @parts;
    for my $run_by (@{$self->run_by}) {
        push @parts, sprintf('username__in=%s', $run_by);
    }
    return join(';', @parts);
}

sub before_query {
    my $self = shift;
    return unless $self->has_started_before;

    return sprintf('date_started__lte=%s', $self->started_before);
}

sub after_query {
    my $self = shift;
    return unless $self->has_started_after;

    return sprintf('date_started__gte=%s', $self->started_after);
}

sub ended_before_query {
    my $self = shift;
    return unless $self->has_ended_before;

    return sprintf('date_ended__lte=%s', $self->ended_before);
}

sub ended_after_query {
    my $self = shift;
    return unless $self->has_ended_after;

    return sprintf('date_ended__gte=%s', $self->ended_after);
}

sub source_path_query {
    my $self = shift;
    return unless $self->has_source_paths;

    my @parts;
    for my $path (@{$self->source_paths}) {
        push @parts, sprintf('source_path__in=%s', $path);
    }
    return join(';', @parts);
}

sub status_query {
    my $self = shift;
    return unless $self->has_statuses;

    my @parts;
    for my $status (@{$self->statuses}) {
        push @parts, sprintf('status__in=%s', $status);
    }
    return join(';', @parts);
}

1;

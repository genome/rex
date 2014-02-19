package Rex::CLI::Reporter;

use Moose::Role;
use warnings FATAL => 'all';

use Procera::Curator;

requires 'print_report';
with 'MooseX::Getopt';

has _curator => (
    is => 'rw',
    isa => 'Procera::Curator',
    predicate => 'has_curator',
);

sub run {
    my $self = shift;

    if (my $actual_path = eval{$self->curator->actual_path}) {
        $self->print_report();
    } else {
        printf "%s is not a Tool or Process\n", $self->curator->source_path;
        exit 1;
    }
}

sub curator {
    my $self = shift;

    unless ($self->has_curator) {
        $self->_curator(Procera::Curator->new(source_path => $self->source_path))
    }
    return $self->_curator;
}

sub source_path {
    my $self = shift;

    my @extra_argv = (@{$self->extra_argv});
    my $path = shift @extra_argv;
    if (!defined($path) || scalar(@extra_argv)) {
        $self->print_actual_usage;
        exit 1;
    }
    return $path;
}

sub print_actual_usage {
    my $self = shift;
    print $self->actual_usage . "\n";
}

sub actual_usage {
    my $self = shift;

    my $search = '\[long options...\]';
    my $replace = 'TOOL::OR::PROCESS';
    (my $usage = $self->usage) =~ s/$search/$replace/;
    return $usage;
}

1;

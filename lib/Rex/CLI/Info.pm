package Rex::CLI::Info;
use Moose;
use warnings FATAL => 'all';

use Data::Dump qw(pp);
use Procera::Curator;
use List::Util qw(max);

with 'MooseX::Getopt';

has 'inputs' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'i',
    cmd_aliases => ['inputs'],
    documentation => 'Display inputs',
);
has 'params' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'p',
    cmd_aliases => ['params'],
    documentation => 'Display params',
);
has 'outputs' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'o',
    cmd_aliases => ['outputs'],
    documentation => 'Display outputs',
);

sub run {
    my $self = shift;

    my $curator = Procera::Curator->new(source_path => $self->source_path);

    if (my $actual_path = eval{$curator->actual_path}) {
        $self->print_report($curator);
    } else {
        printf "%s is not a Tool or Process", $curator->source_path;
        exit 1;
    }
}

sub print_report {
    my ($self, $curator) = @_;

    printf "%s is a %s\n", $curator->source_path, $curator->type;
    printf "Location: %s\n", $curator->actual_path;
    printf "Inputs:\n%s\n", indent(list($curator->inputs), '  ') if $self->inputs;
    printf "Params:\n%s\n", indent(hash($curator->params), '  ') if $self->params;
    printf "Outputs:\n%s\n", indent(list($curator->outputs), '  ') if $self->outputs;

}

sub indent {
    my ($string, $prefix) = @_;

    return $prefix . join("\n$prefix", split(/\n/, $string));
}

sub list {
    my $arrayref = shift;
    return join("\n", @{$arrayref});
}

sub hash {
    my $hashref = shift;
    my $max_width = max map {length($_)} keys %{$hashref};

    my @lines;
    for my $key (sort keys %{$hashref}) {
        my $format = "%-" . $max_width . "s => %s";
        my $value = defined($hashref->{$key}) ? $hashref->{$key} : 'undef';
        push @lines, sprintf($format, $key, $value);
    }
    return join("\n", @lines);
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


__PACKAGE__->meta->make_immutable;

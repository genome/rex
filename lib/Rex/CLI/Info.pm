package Rex::CLI::Info;
use Moose;
use warnings FATAL => 'all';

use Data::Dump qw(pp);
use Procera::Curator;
use List::Util qw(max);
use Scalar::Util qw(looks_like_number);

with 'MooseX::Getopt';
with 'Rex::CLI::Color';

has 'inputs' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'i',
    cmd_aliases => ['inputs'],
    documentation => 'display inputs',
);
has 'params' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'p',
    cmd_aliases => ['params'],
    documentation => 'display params',
);
has 'outputs' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'o',
    cmd_aliases => ['outputs'],
    documentation => 'display outputs',
);

sub run {
    my $self = shift;

    my $curator = Procera::Curator->new(source_path => $self->source_path);

    if (my $actual_path = eval{$curator->actual_path}) {
        $self->print_report($curator);
    } else {
        printf "%s is not a Tool or Process\n", $curator->source_path;
        exit 1;
    }
}

sub print_report {
    my ($self, $curator) = @_;

    printf "\n%s\n", $self->color_heading($curator->source_path);
    printf "%s\n", $self->color_pair('Location', $curator->actual_path);
    printf "%s\n", $self->color_pair('Type', $curator->type);
    if ($self->inputs) {
        printf "%s\n%s\n",
            $self->color_dim('Inputs:'),
            indent($self->list($curator->inputs), '  ');
    }
    if ($self->params) {
        printf "%s\n%s\n",
            $self->color_dim('Params:'),
            indent($self->hash($curator->params), '  ');
    }
    if ($self->outputs) {
        printf "%s\n%s\n",
            $self->color_dim('Outputs:'),
            indent($self->list($curator->outputs), '  ');
    }
}

sub indent {
    my ($string, $prefix) = @_;

    return $prefix . join("\n$prefix", split(/\n/, $string));
}

sub list {
    my $self = shift;
    my $arrayref = shift;
    return join("\n", map {$self->color($_, 'bold')} @{$arrayref});
}

sub hash {
    my $self = shift;
    my $hashref = shift;

    my @unset_params = grep {!defined($hashref->{$_})} keys %{$hashref};
    my @lines;
    for my $unset_param (sort @unset_params) {
        push @lines, $self->colorize_key($unset_param, 'undef');
    }

    my @set_params = grep {defined($hashref->{$_})} keys %{$hashref};
    my $max_width = max map {length($_)} @set_params;
    for my $key (sort @set_params) {
        my $value = $hashref->{$key};
        if (defined($value)) {
            if (!looks_like_number($value)) {
                $value = "'$value'";
            }
        } else {
            $value = 'undef';
        }

        my $num_spaces = $max_width - length($key);
        push @lines, sprintf('%s%s = %s', $self->colorize_key($key, $value),
            ' 'x$num_spaces, $self->colorize_value($value));
    }
    return join("\n", @lines);
}

sub colorize_value {
    my ($self, $value) = @_;

    if ($value eq 'undef') {
        return $self->color_dim($value);
    } else {
        return $self->color($value, 'bold');
    }
}

sub colorize_key {
    my ($self, $key, $value) = @_;

    my @parts = split(/\./, $key);
    my $suffix;
    if ($value eq 'undef') {
        $suffix = $self->color(pop @parts, 'bold');
    } else {
        $suffix = $self->color_dim(pop @parts);
    }
    my $prefix = $self->color_dim(join('.', @parts));

    if (scalar(@parts)) {
        return "$prefix.$suffix";
    } else {
        return $suffix;
    }
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

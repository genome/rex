package Rex::CLI::Color;

use Moose::Role;
use warnings FATAL => 'all';
use Term::ANSIColor qw(colored);

has 'has_color' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Bool',
    default => 0,
    cmd_flag => 'c',
    cmd_aliases => ['color'],
    documentation => 'print in color',
);

sub color {
    my $self = shift;
    my $string = shift;

    if(-t STDOUT and -t STDERR and $self->has_color and @_) {
        return colored($string, @_);
    } else {
        return $string;
    }
}

sub color_heading {
    my ($self, $text) = @_;
    return $self->color_dim('=== ') . $self->color($text, 'bold') .
        $self->color_dim(' ===');
}

sub color_pair {
    my ($self, $key, $value) = @_;
    return $self->color_dim($key.':') . ' ' . ($value || '');
}

sub color_dim {
    my ($self, $text) = @_;
    return $self->color($text, 'white');
}

my %STATUS_COLORS = (
    'running' => 'cyan',
    'succeeded' => 'green',
    'crashed' => 'red',
);

sub color_status {
    my ($self, $status) = @_;
    return $self->color($status, $STATUS_COLORS{$status});
}


1;

package InputFile::Entry;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);

use Text::CSV qw();
use Memoize qw();

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has value => (
    is => 'rw',
    isa => 'Value|Undef',
);

sub assert_has_value {
    my $self = shift;

    unless (defined($self->value)) {
        confess sprintf("Input entry %s has no value",
            $self->name);
    }

    return;
}

my $_CSV = Text::CSV->new({binary => 1, sep_char => "\t"});
sub write {
    my ($self, $file_handle) = @_;

    printf $file_handle "%s\n", $self->as_string;

    return;
}

sub as_string {
    my $self = shift;

    my @columns = ($self->name);
    if (defined($self->value)) {
        push @columns, $self->value;
    }

    $_CSV->combine(@columns);
    return $_CSV->string;
}
Memoize::memoize('as_string');

sub as_sortable_string {
    my $self = shift;

    (my $sortable_string = $self->as_string) =~ s/STEP_LABEL_[^\t]*/STEP_LABEL_1/;
    return $sortable_string;
}

sub create_from_line {
    my ($class, $line) = @_;

    unless ($_CSV->parse($line)) {
        confess sprintf("Failed to parse line: %s", $line);
    }
    my @columns = $_CSV->fields;

    unless (scalar(@columns) > 0 && scalar(@columns) < 3) {
        confess sprintf(
            "Bad number of columns (%s) in line, expected 1 or 2: [%s]",
            scalar(@columns), join(', ', map {sprintf("'%s'", $_)} @columns));
    }

    my ($name, $value) = @columns;

    return $class->new(name => $name, value => $value);
}

1;

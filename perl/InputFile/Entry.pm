package InputFile::Entry;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use Text::CSV qw();


class InputFile::Entry {
    has => [
        name => {
            is => 'Text',
        },
        type => {
            is => 'Text',
        },

        value => {
            is => 'Text',
            is_optional => 1,
        },
    ],
};


sub assert_has_value {
    my $self = shift;

    unless ($self->value) {
        confess sprintf("Input entry %s (%s) has no value",
            $self->type, $self->name);
    }

    return;
}

my $_CSV = Text::CSV->new({binary => 1, sep_char => "\t"});
sub write {
    my ($self, $file_handle) = @_;

    my @columns = ($self->type, $self->name);
    if ($self->value) {
        push @columns, $self->value;
    }

    $_CSV->combine(@columns);
    printf $file_handle "%s\n", $_CSV->string;

    return;
}

sub create_from_line {
    my ($class, $line) = @_;

    unless ($_CSV->parse($line)) {
        confess sprintf("Failed to parse line: %s", $line);
    }
    my @columns = $_CSV->fields;

    unless (scalar(@columns) > 1 && scalar(@columns) < 4) {
        confess sprintf(
            "Bad number of columns (%s) in line, expected 2 or 3: [%s]",
            scalar(@columns), join(', ', map {sprintf("'%s'")} @columns));
    }

    my ($type, $name, $value) = @columns;
    return $class->create(name => $name, type => $type, value => $value);
}

1;

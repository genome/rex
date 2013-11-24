package InputFile::Entry;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use Text::CSV qw();
use Memoize qw();


class InputFile::Entry {
    id_generator => '-uuid',

    has => [
        name => {
            is => 'Text',
        },
        tags => {
            is => 'ARRAY',
        },

        value => {
            is => 'Text',
            is_optional => 1,
        },
    ],
};

sub has_tag {
    my ($self, $tag) = @_;

    my $result = 0;
    for my $entry_tag (@{$self->tags}) {
        if ($tag eq $entry_tag) {
            $result = 1;
            last;
        }
    }
    return $result;
}

sub has_tag_like {
    my ($self, $regex) = @_;

    my $result = 0;
    for my $entry_tag (@{$self->tags}) {
        if ($entry_tag =~ /$regex/) {
            $result = 1;
            last;
        }
    }
    return $result;
}

sub assert_has_value {
    my $self = shift;

    unless (defined($self->value)) {
        confess sprintf("Input entry %s tags=[%s] has no value",
            $self->name, join(', ', @{$self->tags}));
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

    my @columns = (join(',', @{$self->tags}), $self->name);
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

    unless (scalar(@columns) > 1 && scalar(@columns) < 4) {
        confess sprintf(
            "Bad number of columns (%s) in line, expected 2 or 3: [%s]",
            scalar(@columns), join(', ', map {sprintf("'%s'")} @columns));
    }

    my ($tags_part, $name, $value) = @columns;
    my @tags = split(/,/, $tags_part);

    return $class->create(name => $name, tags => \@tags, value => $value);
}

1;

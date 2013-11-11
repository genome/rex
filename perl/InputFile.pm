package InputFile;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use InputFile::Entry;


class InputFile {
    has => [
        entries => {
            is => 'InputFile::Entry',
            is_many => 1,
        },
    ],
};


sub create_from_file_handle {
    my ($class, $file_handle) = @_;

    my @entries;
    for my $line (<$file_handle>) {
        push @entries, InputFile::Entry->create_from_line($line);
    }

    my $self = $class->create(entries => \@entries);

    return $self;
}


sub create_from_inputs_and_constants {
    my ($class, $inputs, $constants) = @_;

    my @entries;
    push @entries, map {InputFile::Entry->create(name => $_->name,
            type => $_->type, value => $constants->{$_->name})} @$inputs;

    my $self = $class->create(entries => \@entries);

    return $self;
}


sub write {
    my ($self, $file_handle) = @_;

    for my $entry ($self->entries) {
        $entry->write($file_handle);
    }

    return;
}

sub as_hash {
    my $self = shift;

    $self->validate_completeness;

    my %result;
    for my $entry ($self->entries) {
        $result{$entry->name} = $entry->value;
    }

    return %result;
}

sub validate_completeness {
    my $self = shift;

    $self->_validate_no_duplicate_names;
    $self->_validate_no_missing_values;

    return;
}

sub _validate_no_missing_values {
    my $self = shift;

    for my $entry ($self->entries) {
        $entry->assert_has_value;
    }

    return;
}

sub _validate_no_duplicate_names {
    my $self = shift;

    my %names;
    for my $entry ($self->entries) {
        if (exists $names{$entry->name}) {
            confess sprintf("Duplciate input found for '%s'", $entry->name);
        } else {
            $names{$entry->name} = 1;
        }
    }

    return;
}


1;

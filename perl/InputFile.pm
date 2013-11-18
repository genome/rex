package InputFile;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);
use List::MoreUtils qw();
use IO::File qw();

use InputFile::Entry;


class InputFile {
    has => [
        entries => {
            is => 'InputFile::Entry',
            is_many => 1,
        },
    ],
};


sub create_from_filename {
    my ($class, $filename) = @_;

    my $fh = IO::File->new($filename, 'r');
    my $self = $class->create_from_file_handle($fh);
    $fh->close;

    return $self;
}

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

    for my $entry (@entries) {
        if ($entry->type =~ /STEP_LABEL/) {
            $entry->value($entry->name);
        }
    }

    my $self = $class->create(entries => \@entries);

    return $self;
}

sub write_to_filename {
    my ($self, $filename) = @_;

    my $fh = IO::File->new($filename, 'w');
    $self->write($fh);
    $fh->close;

    return;
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

sub unique_input_name_for {
    my ($self, $type) = @_;

    my @found_entries = grep {$_->type eq $type
                              && !defined($_->value)} $self->entries;
    unless (scalar(@found_entries) == 1) {
        confess sprintf("Found multiple entries of type '%s': [%s]",
            $type, join(', ',
                map {sprintf("'%s' => '%s'", $_->name, $_->value || '')}
                @found_entries)
        );
    }

    return $found_entries[0]->name;
}

sub set_process {
    my ($self, $url) = @_;

    my $process_input_name = $self->unique_input_name_for('PROCESS');
    $self->set_inputs($process_input_name => $url);

    return;
}

sub set_test_name {
    my ($self, $value) = @_;

    my $test_name_name = $self->unique_input_name_for('TEST_NAME');
    $self->set_inputs($test_name_name => $value);

    return;
}

sub set_inputs {
    my $self = shift;
    my %params = @_;

    for my $name (keys %params) {
        my $entry = $self->entry_named($name);
        # NOTE: We cannot use $entry->value($params{$name}), because UR
        #       erroneously says that undef and '' are the same.
        $entry->{value} = $params{$name};
        $entry->assert_has_value;
    }

    return;
}

sub entry_named {
    my ($self, $name) = @_;

    $self->_validate_no_duplicate_names;

    return List::MoreUtils::first_value {$_->name eq $name} $self->entries;
}


sub update {
    my ($self, $other) = @_;

    for my $other_entry ($other->entries) {
        my $self_entry = $self->entry_named($other_entry->name);
        $self_entry->value($other_entry->value);
    }

    return;
}


1;

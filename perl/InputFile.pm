package InputFile;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::MoreUtils qw();
use IO::File qw();

use InputFile::Entry;
use Data::Dumper;

has entries => (
    is => 'rw',
    isa => 'ArrayRef[InputFile::Entry]',
    default => sub {[]},
);

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

    my $self = $class->new(entries => \@entries);

    return $self;
}


sub create_from_inputs_and_constants {
    my ($class, $inputs, $constants) = @_;

    my @entries;
    my @inputs = values %{$inputs};
    push @entries, map {InputFile::Entry->new(name => $_->name,
            tags => $_->tags, value => $constants->{$_->name})} @inputs;

    for my $entry (@entries) {
        if ($entry->has_tag_like('STEP_LABEL')) {
            $entry->value($entry->name);
        }
    }

    my $self = $class->new(entries => \@entries);

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

    for my $entry (sort {$a->as_sortable_string cmp $b->as_sortable_string} @{$self->entries}) {
        $entry->write($file_handle);
    }

    return;
}

sub as_hash {
    my $self = shift;

    $self->validate_completeness;

    my %result;
    for my $entry (@{$self->entries}) {
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

    for my $entry (@{$self->entries}) {
        $entry->assert_has_value;
    }

    return;
}

sub _validate_no_duplicate_names {
    my $self = shift;

    my %names;
    for my $entry (@{$self->entries}) {
        if (exists $names{$entry->name}) {
            confess sprintf("Duplciate input found for '%s'", $entry->name);
        } else {
            $names{$entry->name} = 1;
        }
    }

    return;
}

sub set_process {
    my ($self, $url) = @_;

    my %process_hash;
    for my $entry (@{$self->entries}) {
        if ($entry->has_tag('PROCESS')) {
            $process_hash{$entry->name} = $url;
        }
    }
    $self->set_inputs(%process_hash);

    return;
}

sub set_test_name {
    my ($self, $value) = @_;

    my %test_name_hash;
    for my $entry (@{$self->entries}) {
        if ($entry->has_tag('TEST_NAME')) {
            $test_name_hash{$entry->name} = $value;
        }
    }
    $self->set_inputs(%test_name_hash);

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

    return List::MoreUtils::first_value {$_->name eq $name} @{$self->entries};
}


sub update {
    my ($self, $other) = @_;

    for my $other_entry (@{$other->entries}) {
        my $self_entry = $self->entry_named($other_entry->name);
        $self_entry->value($other_entry->value);
    }

    return;
}


1;

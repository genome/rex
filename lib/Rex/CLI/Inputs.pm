package Rex::CLI::Inputs;

use Moose;
use warnings FATAL => 'all';

use File::Utility qw(open_file_for_writing);
use IO::Handle;
use Memoize;

with 'MooseX::Getopt';
with 'Rex::CLI::Reporter';

has 'filename' => (
    traits => ['Getopt'],
    is => 'ro',
    isa => 'Str',
    required => 0,
    cmd_flag => 'o',
    cmd_aliases => ['output-filename'],
    documentation => 'output will be written to this file instead of to STDOUT',
    predicate => 'has_filename',
);

sub print_report {
    my $self = shift;

    my $prefix = $self->_prefix;
    my %params = %{$self->curator->params};
    my $handle = $self->_handle;

    for my $name (keys %params) {
        unless (defined($params{$name})) {
            print $handle "$prefix$name\t\n";
        }
    }
    for my $name (@{$self->curator->inputs}) {
        print $handle "$name\t\n";
    }
}

sub _prefix {
    my $self = shift;
    if ($self->curator->type eq 'Tool') {
        my @pieces = split(/::/, $self->curator->source_path);
        return $pieces[-1] . '.';
    } else {
        return '';
    }
}

sub _handle {
    my $self = shift;

    my $handle;
    if ($self->has_filename) {
        $handle = open_file_for_writing($self->filename);
    } else {
        $handle = new IO::Handle;
        STDOUT->autoflush(1);
        $handle->fdopen(fileno(STDOUT), 'w');
    }
    return $handle;
}
Memoize::memoize('_handle');


__PACKAGE__->meta->make_immutable;

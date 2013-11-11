package Runner;

use strict;
use warnings FATAL => 'all';

use UR;
use Carp qw(confess);

use IO::File qw();
use InputFile;


class Runner {
    is => 'Command::V2',

    has_input => [
        workflow => {
            is => 'Path',
        },

        inputs => {
            is => 'Path',
        },
    ],
};


sub execute {
    my $self = shift;

    my %inputs_hash = $self->inputs_hash;
    print Data::Dumper::Dumper(\%inputs_hash);

    1;
}

sub inputs_hash {
    my $self = shift;

    my $inputs_fh = IO::File->new($self->inputs, 'r');
    my $input_file = InputFile->create_from_file_handle($inputs_fh);
    $inputs_fh->close;

    return $input_file->as_hash;
}


1;

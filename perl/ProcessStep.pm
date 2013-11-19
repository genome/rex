package ProcessStep;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;

use File::Spec qw();
use File::Find::Rule qw();
use Memoize qw();
use Genome;


class ProcessStep {
    table_name => 'experimental.process_step',
    schema_name => 'GMSchema',
    data_source => 'Genome::DataSource::GMSchema',

    id_by => [
        process_id => {
            is => 'Text',
            len => 36,
        },
        result_id => {
            is => 'Text',
            len => 36,
        },
    ],

    has => [
        label => {
            is => 'Text',
            len => 4096,
        },
    ],

    has_optional => [
        process => {
            is => 'Process',
            id_by => 'process_id',
        },
        result => {
            is => 'Result',
            id_by => 'result_id',
        },
    ],
};


sub link {
    my ($self, $target_directory) = @_;

    $self->_make_link_directory($target_directory);
    $self->_link_files($target_directory);

    return;
}

sub _relative_link_directory {
    my $self = shift;

    my @components = split /\./, $self->label;
    pop @components;
    return File::Spec->join(@components);
}
Memoize::memoize('_relative_link_directory');

sub _link_directory {
    my ($self, $target_directory) = @_;

    return File::Spec->join($target_directory, $self->_relative_link_directory);
}

sub _make_link_directory {
    my ($self, $target_directory) = @_;

    File::Path::make_path($self->_link_directory($target_directory));

    return;
}

sub _link_files {
    my ($self, $target_directory) = @_;

    for my $file (File::Find::Rule->file->in(
            $self->result->allocation->absolute_path)) {
        my ($name, $path) = File::Basename::fileparse($file);
        Genome::Sys->create_symlink($file,
            File::Spec->join($self->_link_directory($target_directory), $name));
    }

    return;
}


1;

package Factory::ManifestAllocation;

use strict;
use warnings FATAL => 'all';

use Manifest::Reader;
use Manifest::Writer;
use File::Spec qw();
use File::Basename qw();
use File::Path qw();
use Params::Validate qw();

use Factory::Allocation;

sub from_manifest {
    my $manifest_file = shift;

    my $reader = Manifest::Reader->create(manifest_file => $manifest_file);
    my $allocation = Factory::Allocation::from_kilobytes_requested(
        $reader->total_kilobytes);

    my $writer = Manifest::Writer->create(
        manifest_file => File::Spec->join($allocation->absolute_path,
            'manifest.xml'));
    for my $entry ($reader->entries) {

        my $dest_path = File::Spec->join($writer->base_path, $entry->{path});
        _make_path_to($dest_path);
        Genome::Sys->copy_file($reader->path_to($entry->{tag}), $dest_path);

        $writer->add_file(%$entry);
    }
    $writer->save;

    $allocation->reallocate;

    return $allocation;
}

sub _make_path_to {
    my $full_path = shift;

    my ($file, $path) = File::Basename::fileparse($full_path);

    File::Path::make_path($path);

    return;
}


1;

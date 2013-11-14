package Factory::ManifestAllocation;

use strict;
use warnings FATAL => 'all';

use Manifest::Reader;
use Manifest::Writer;
use File::Spec qw();
use Params::Validate qw();
use Data::UUID qw();

use Genome::Disk::Allocation;


sub from_manifest {
    my $manifest_file = shift;

    my $reader = Manifest::Reader->create(manifest_file => $manifest_file);
    my $allocation = Genome::Disk::Allocation->create(
        allocation_path => _generate_allocation_path(),
        disk_group_name => 'info_genome_models',
        owner_class_name => 'Genome::Sys::User',
        owner_id => 'mburnett@genome.wustl.edu',
        kilobytes_requested => $reader->total_kilobytes);

    my $writer = Manifest::Writer->create(
        manifest_file => File::Spec->join($allocation->absolute_path,
            'manifest.xml'));
    for my $entry ($reader->entries) {

        Genome::Sys->copy_file($reader->path_to($entry->{tag}),
            File::Spec->join($writer->base_path, $entry->{path}));

        $writer->add_file(%$entry);
    }
    $writer->save;

    return $allocation;
}

sub _generate_allocation_path {
    my $uuid = Data::UUID->new->create_hex;
    return File::Spec->join('model_data',
        substr($uuid, 2, 3), substr($uuid, 5));
}


1;

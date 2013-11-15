package Factory::Allocation;

use strict;
use warnings FATAL => 'all';

use Data::UUID qw();

use Genome::Disk::Allocation;
use Genome::Sys;


sub from_kilobytes_requested {
    my $kilobytes_requested = shift;

    my $owner = Genome::Sys->current_user;
    my $allocation = Genome::Disk::Allocation->create(
        allocation_path => _generate_allocation_path(),
        disk_group_name => 'info_genome_models',
        owner_class_name => $owner->class,
        owner_id => $owner->id,
        kilobytes_requested => $kilobytes_requested);
}

sub _generate_allocation_path {
    my $uuid = Data::UUID->new->create_hex;
    return File::Spec->join('model_data',
        substr($uuid, 2, 3), substr($uuid, 5));
}


1;

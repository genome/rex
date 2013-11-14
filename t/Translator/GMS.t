BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
};

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use URI::URL qw();

use Manifest::Writer;
use Genome::Disk::Allocation;
use File::Basename qw();

use_ok('Translator::GMS');


subtest specified_host_dies => sub {
    my $url = new URI::URL 'gms://host:port/data/12345?tag=bam';
    dies_ok {Translator::GMS->fetch($url)} 'specified host dies';
};

subtest echo_returns_file_path => sub {
    my $url = new URI::URL 'gms:///echo/12345/bam';
    is(Translator::GMS->fetch($url), '/12345/bam',
        'echo returns path');
};


sub create_and_populate_allocation {
    my %params = @_;
    my $allocation = Genome::Disk::Allocation->create(
        kilobytes_requested => 16,
        disk_group_name => 'info_genome_models',
        owner_class_name => 'UR::Value',
        owner_id => 42,
        allocation_path => Genome::Sys->md5sum_data(join('|', @_)),
    );

    my $manifest = Manifest::Writer->create(
        manifest_file => path_in_allocation($allocation, 'manifest.xml'));
    for my $file_tag (keys %params) {
        my $path = path_in_allocation($allocation, $params{$file_tag});
        touch_file($path);
        $manifest->add_file(path => $path, tag => $file_tag, kilobytes => 0);
    }
    $manifest->save;

    return $allocation;
}

sub path_in_allocation {
    my ($allocation, $path) = @_;

    return sprintf('%s/%s', $allocation->absolute_path, $path);
}

sub touch_file {
    my $path = shift;

    my ($name, $dir) = File::Basename::fileparse($path);
    `mkdir -p $dir`;
    `touch $path`;

    return;
}

subtest data_returns_path_in_allocation => sub {
    my $file_tag = 'foo';
    my $file_path = 'bar/baz.test';
    my $allocation = create_and_populate_allocation(
        $file_tag => $file_path);

    my $url = new URI::URL sprintf(
        'gms:///data/%s?tag=%s', $allocation->id, $file_tag);
    is(Translator::GMS->fetch($url),
        path_in_allocation($allocation, $file_path),
        'basic manifest lookup works');
};


done_testing;

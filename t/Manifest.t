use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use Manifest;
use File::Find::Rule qw();
use File::Spec qw();
use File::Basename qw();


sub valid_manifest_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'Manifest/valid');
}

sub invalid_manifest_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'Manifest/invalid');
}

sub test_files {
    my $base_path = shift;
    my @a = File::Find::Rule->file->maxdepth(1)->in($base_path);
    return @a;
}


subtest base_path => sub {
    my $m = Manifest->create(manifest_file => '/tmp/foo/bar.xml');
    is($m->base_path, '/tmp/foo/');
};

subtest schema_path => sub {
    is(Manifest::schema_path(), 'perl/manifest.xsd');
};


subtest 'valid manifests' => sub {
    for my $valid_manifest (test_files(valid_manifest_base_dir())) {
        my $manifest = Manifest->create(manifest_file => $valid_manifest);
        lives_ok { $manifest->validate }
            sprintf('valid manfiest lives (%s)', $valid_manifest);
    }
};

subtest 'invalid manifests' => sub {
    for my $invalid_manifest (test_files(invalid_manifest_base_dir())) {
        my $manifest = Manifest->create(manifest_file => $invalid_manifest);
        dies_ok { $manifest->validate }
            sprintf('invalid manifest dies (%s)', $invalid_manifest);
    }
};


done_testing;

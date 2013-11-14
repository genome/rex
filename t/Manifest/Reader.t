use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use File::Find::Rule qw();
use File::Spec qw();
use File::Basename qw();


use_ok('Manifest::Reader');


sub valid_manifest_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'Reader/valid');
}

sub invalid_manifest_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'Reader/invalid');
}

sub test_files {
    my $base_path = shift;
    my @a = File::Find::Rule->file->maxdepth(1)->in($base_path);
    return @a;
}


subtest base_path => sub {
    my $m = Manifest::Reader->create(manifest_file => '/tmp/foo/bar.xml');
    is($m->base_path, '/tmp/foo/');
};

subtest schema_path => sub {
    is(Manifest::Detail::ReaderWriterBase::schema_path(),
        File::Spec->rel2abs('perl/Manifest/Detail/manifest.xsd'));
};


subtest 'valid manifests' => sub {
    for my $valid_manifest (test_files(valid_manifest_base_dir())) {
        my $manifest = Manifest::Reader->create(
            manifest_file => $valid_manifest);
        lives_ok { $manifest->validate }
            sprintf('valid manfiest lives (%s)', $valid_manifest);
    }
};

subtest 'invalid manifests' => sub {
    for my $invalid_manifest (test_files(invalid_manifest_base_dir())) {
        my $manifest = Manifest::Reader->create(
            manifest_file => $invalid_manifest);
        dies_ok { $manifest->validate }
            sprintf('invalid manifest dies (%s)', $invalid_manifest);
    }
};


sub sample_manifest_file {
    return File::Spec->join(valid_manifest_base_dir(),
        'simple_manifest.xml');
}

subtest path_to => sub {
    my $manifest = Manifest::Reader->create(
        manifest_file => sample_manifest_file());
    is($manifest->path_to('foo'),
        File::Spec->join($manifest->base_path, 'bar'),
        'good lookup OK');
    dies_ok { $manifest->path_to('bad') } 'bad lookup dies';
};

subtest entries => sub {
    my $manifest = Manifest::Reader->create(
        manifest_file => sample_manifest_file());
    my @entries = $manifest->entries;
    is_deeply(\@entries, [{path => 'bar', tag => 'foo'}], 'entires ok');
};


done_testing;

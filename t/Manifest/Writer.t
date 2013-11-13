use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use Genome::Utility::Test qw(compare_ok);

use File::Temp qw();

use_ok('Manifest::Writer');


sub new_writer {
    my $fh = File::Temp->new(UNLINK => 0, SUFFIX => '.xml');

    my $writer = Manifest::Writer->create(
        manifest_file => $fh->filename,
    );

    return $writer;
}

subtest empty_manifest => sub {
    my $writer = new_writer();
    dies_ok { $writer->validate } 'empty manifest fails validation';
};


sub expected_simple_manifest {
    my ($name, $path) = File::Basename::fileparse(__FILE__);

    return File::Spec->join($path, 'writer_simple_manifest.xml');
}

subtest simple_manifest => sub {
    my $writer = new_writer();

    $writer->add_file(tag => 'foo', path => 'bar');

    lives_ok { $writer->validate } 'simple manifest validates';

    $writer->save;
    compare_ok($writer->manifest_file, expected_simple_manifest(),
        'simple manifest written correctly');
};


done_testing;

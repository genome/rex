use strict;
use warnings FATAL => 'all';

use Test::More;

use File::Find::Rule qw();
use File::Spec qw();
use File::Basename qw();

use TestHelper qw();


sub system_test_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    print "$name:$path:$suffix\n";

    return File::Spec->join($path, 'SystemTest');
}

sub test_dirs {
    my @a = File::Find::Rule->directory->maxdepth(1)->in(
        system_test_base_dir());
    shift @a;
    return @a;
}

sub source_file {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'root.gms');
}

sub compiler_expected_result {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'compiler-output');
}

sub label {
    my $test_dir = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse($test_dir);

    return $name;
}


for my $test_dir (test_dirs()) {
    my $output_directory = File::Temp::tempdir(CLEANUP => 1);
    TestHelper::compile(source_file($test_dir), $output_directory,
        label($test_dir));

    TestHelper::diff_directories(compiler_expected_result($test_dir),
        $output_directory, label($test_dir));
}

done_testing();

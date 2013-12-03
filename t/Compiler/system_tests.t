use strict;
use warnings FATAL => 'all';

$SIG{__DIE__} = sub {
    local $Carp::CarpLevel = 1;
    &Carp::confess;
};

use Test::More;

use File::Find::Rule qw();
use File::Spec qw();
use File::Basename qw();

use Compiler::TestHelper qw();


sub system_test_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'SystemTest');
}

sub test_dirs {
    my @a = File::Find::Rule->directory->maxdepth(1)->in(
        system_test_base_dir());
    shift @a;
    return @a;
}

sub label {
    my $test_dir = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse($test_dir);

    return $name;
}


sub should_update_directory {
    return $ENV{UPDATE_TEST_DATA} || undef;
}

for my $test_dir (test_dirs()) {
    subtest $test_dir => sub {
        my $output_directory = File::Temp::tempdir(CLEANUP => 1);
        Compiler::TestHelper::compile($test_dir, $output_directory,
            label($test_dir));

        Compiler::TestHelper::diff_directories($test_dir,
            $output_directory, label($test_dir));

        if (defined(should_update_directory())) {
            Compiler::TestHelper::update_directory(
                $test_dir, $output_directory);
        }
    };
}

done_testing();

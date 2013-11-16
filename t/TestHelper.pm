package TestHelper;

use strict;
use warnings FATAL => 'all';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    run_basic_test
    diff_ast_files
    diff_xml_files
);

use Carp qw(confess);
use Test::More;
use File::Temp;

use Genome::Utility::Test qw(compare_ok);

use UR;
use Compiler;

sub compile {
    my ($input_file, $output_directory, $label) = @_;

    my $cmd = Compiler->create(
        input_file => $input_file,
        output_directory => $output_directory,
    );

    ok($cmd->execute, sprintf('command ran (%s)', $label)) || die;
    return;
}

my @_FILENAMES = (
    'workflow.xml',
    'inputs.tsv'
);
sub update_directory {
    my ($old, $new) = @_;

    for my $filename (@_FILENAMES) {
        my $result = File::Copy::copy(
            File::Spec->join($new, $filename),
            File::Spec->join($old, $filename),
        );
        confess 'failed to copy file' unless $result;
    }

    return;
}

sub diff_directories {
    my ($expected, $actual, $label) = @_;

    for my $filename (@_FILENAMES) {
        compare_ok(
            File::Spec->join($expected, $filename),
            File::Spec->join($actual, $filename),
            sprintf('%s compares ok (%s)', $filename, $label));

    }

    return;
}

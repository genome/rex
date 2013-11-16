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

    diff_xml_files(
        File::Spec->join($expected, 'workflow.xml'),
        File::Spec->join($actual, 'workflow.xml'),
        $label,
    );

    diff_input_files(
        File::Spec->join($expected, 'inputs.tsv'),
        File::Spec->join($actual, 'inputs.tsv'),
        $label,
    );

    return;
}

sub diff_xml_files {
    my ($blessed, $new, $label) = @_;

    sort_then_diff_files($blessed, $new, $label, 'xml');
}

sub diff_input_files {
    my ($blessed, $new, $label) = @_;

    sort_then_diff_files($blessed, $new, $label, 'input');
}

sub sort_then_diff_files {
    my ($blessed, $new, $label, $file_type) = @_;
    ok(-f $blessed, sprintf('found blessed %s file (%s)', $file_type, $label));
    ok(-f $new, sprintf('found new %s file (%s)', $file_type, $label));

    my $diff = `bash -c 'diff <(sort $blessed) <(sort $new)'`;
    is($diff, '', sprintf('%s files are the same (%s)', $file_type, $label));
}

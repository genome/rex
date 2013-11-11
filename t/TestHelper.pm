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

use Test::More;
use File::Temp;

use Genome::Utility::Test qw(compare_ok);

use UR;
use Compiler;

sub run_basic_test {
    my $test_file = shift;

    (my $input_file = $test_file) =~ s/\.t$/.gms/;
    my $output_directory = File::Temp::tempdir(CLEANUP => 1);
    compile($input_file, $output_directory, '');

    my $test_data_directory = $test_file . '.data';
    diff_directories($test_data_directory, $output_directory, '');

    return $test_data_directory, $output_directory;
}

sub compile {
    my ($input_file, $output_directory, $label) = @_;

    my $cmd = Compiler->create(
        input_file => $input_file,
        output_directory => $output_directory,
    );

    ok($cmd->execute, sprintf('command ran (%s)', $label)) || die;
    return;
}

sub diff_directories {
    my ($expected, $actual, $label) = @_;

    diff_xml_files(
        File::Spec->join($expected, 'workflow.xml'),
        File::Spec->join($actual, 'workflow.xml'),
        $label,
    );
    return;
}

sub diff_ast_files {
    my ($blessed, $new, $label) = @_;

    compare_ok($blessed, $new, sprintf('ast files are the same (%s)', $label),
        filters => [qr(^.*['\s]_.*$), qr(^.*'id'.*$),
            qr(^.*[[:xdigit:]]{32}.*$)
        ]);
}

sub diff_xml_files {
    my ($blessed, $new, $label) = @_;

    ok(-f $blessed, sprintf('found blessed xml file (%s)', $label));
    ok(-f $new, sprintf('found new xml file (%s)', $label));

    my $diff = `bash -c 'diff <(sort $blessed) <(sort $new)'`;
    is($diff, '', sprintf('xml files are the same (%s)', $label));
}

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
    my $cmd = Compiler->create(
        input_file => $input_file,
        output_directory => $output_directory,
    );

    ok($cmd->execute, 'command ran') || die;

    my $test_data_directory = $test_file . '.data';
    diff_ast_files(
        File::Spec->join($test_data_directory, 'ast'),
        File::Spec->join($output_directory, 'ast')
    );
    diff_xml_files(
        File::Spec->join($test_data_directory, 'workflow.xml'),
        File::Spec->join($output_directory, 'workflow.xml')
    );
    return $test_data_directory, $output_directory;
}

sub diff_ast_files {
    my ($blessed, $new) = @_;

    compare_ok($blessed, $new, 'ast files are the same',
        filters => [qr(^.*['\s]_.*$), qr(^.*'id'.*$),
            qr(^.*[[:xdigit:]]{32}.*$)
        ]);
}

sub diff_xml_files {
    my ($blessed, $new) = @_;

    ok(-f $blessed, 'found blessed xml file');
    ok(-f $new, 'found new xml file');

    my $diff = `bash -c 'diff <(sort $blessed) <(sort $new)'`;
    is($diff, '', 'xml files are the same');
}

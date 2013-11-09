package TestHelpers;

use strict;
use warnings FATAL => 'all';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    diff_ast_files
    diff_xml_files
);

use Test::More;
use Genome::Utility::Test qw(compare_ok);

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

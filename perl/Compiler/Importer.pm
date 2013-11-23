package Compiler::Importer;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Spec qw();

use Compiler::Parser;

use constant EXTENSION => '.gms';


sub import_file {
    my $source_path = shift;

    my $process_definition_path = resolve_path($source_path);
    if ($process_definition_path) {
        return Compiler::Parser::parse_tree($process_definition_path);
    } else {
        return create_tool_definition($name);
    }
}

sub resolve_path {
    my $name = shift;
    my $relative_path = $name . EXTENSION();

    for my $base_path (search_path()) {
        my $absolute_path = File::Spec->rel2abs(File::Spec->join(
                $base_path, split(/::/, $relative_path)));
        if (-f $absolute_path) {
            return $absolute_path;
        }
    }

    return;
}

sub search_path {
    if ($ENV{GMSPATH}) {
        return split(/:/, $ENV{GMSPATH});
    }
    return 'definitions';
}

1;

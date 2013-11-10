package Compiler::Importer;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use Data::Dumper;
use File::Spec qw();

use Compiler::Parser;

use constant EXTENSION => '.gms';


sub import_file {
    my $name = shift;

    return Compiler::Parser::parse_tree(resolve_path($name));
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

    confess sprintf("Could not find %s in search path: %s",
        $relative_path, Data::Dumper::Dumper(search_path()));
}

sub search_path {
    if ($ENV{GMSPATH}) {
        return split(/:/, $ENV{GMSPATH});
    }
    return 'definitions';
}


1;

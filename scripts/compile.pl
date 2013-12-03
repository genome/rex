#!/usr/bin/env genome-perl

use strict;
use warnings;

use Compiler;
use Tool;

$SIG{__DIE__} = sub {
    local $Carp::CarpLevel = 1;
    &Carp::confess;
};


my $compiler = Compiler->new_with_options();
$compiler->execute();

1;

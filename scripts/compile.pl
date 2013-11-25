#!/usr/bin/env genome-perl

use strict;
use warnings;

use Compiler;
use Tool;

my $compiler = Compiler->new_with_options();
$compiler->execute();

1;

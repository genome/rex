#!/usr/bin/env genome-perl

use strict;
use warnings;

use Compiler::Parser;

Compiler::Parser->execute_with_shell_params_and_exit();

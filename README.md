# DSL Experiment

This repo is an exploration of a general DSL for the Genome Modelling System.


## Contents
* perl/Compiler - translates DSL into a Workflow XML + required inputs list
* perl/Manifest - builds and queries file lists
* perl/Runner - runs Workflow XML given inputs
* perl/Tool - Command objects used by Workflow XML
* definitions - contains re-usable DSL files
* vim - contains vim syntax hilighting files for the DSL
* t/SystemTest - each subdirectory is a separate system test


## TODO
- compiler
    - sugar for addressing "A::B::C" with "B::C" or "C"
    - forbid recursive imports
    - improve parsing error messages (probably with <reject> and <error>)
    - fix string escaping regular expressions (grammar and syntax)
    - improve syntax hilighting of errors
- add array type support (for grouping and parallel)
- add workspace input to Tool
- add locking to Tool
- add array input/output support
- add process template


## Directly Addressed Legacy System Weaknesses
- difficult to make small tweaks to existing processes
- impossible to know exactly what inputs/parameters were used for a process
- impossible to know what process created a SoftwareResult
- difficult to sequence builds/subprocesses
    - composable subprocesses addresses this
- adding "tools" is repetitive
    - Command, SoftwareResult
    - possibly DV2 Classes
    - possibly change to processing profiles
- difficult to know how to find data associated with process
    - often have to look at code to know file paths
- difficult to know how often "tools" are being run
- deadlocking (completely eliminated)

## Indirectly Addressed Legacy System Weaknesses
- difficult to use different storage backends
- data are difficult to secure
    - cannot be made read only because of DV2/symlinks

## Weakness Brainstorm Area
- multiple places to do "orchestration"
    - some "tools" run lots of sub commands & make multiple SoftwareResults
    - makes it difficult to know exactly what work was done in a process
- multiple places to do "work"
    - Models, Builds, SoftwareResults, Commands, etc...
    - difficult to make small changes to a "process"
    - difficult to know what happened during a process
    - much work is "untracked"

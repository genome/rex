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
        - this is partly implemented, it currently requires the shortest form
    - forbid recursive imports
    - improve parsing error messages (probably with <reject> and <error>)
    - fix string escaping regular expressions (grammar and syntax)
    - improve syntax hilighting of errors
    - resolve "ambiguity" of each link separately, that way filters don't try
      to use their own outputs
- add workspace input to Tool
- add locking to Tool
- add array input/output support
- add process template

## Legacy System Weaknesses
### Directly Addressed Legacy System Weaknesses
- difficult (expensive) (for analysts) to modify existing processes
    - what do you have to add (tool, Model/Build, SR, processing profile
      modifications)
- impossible to know exactly what inputs/parameters were used for a process
- impossible to know what process created a SoftwareResult
- difficult to sequence builds/subprocesses
    - composable subprocesses addresses this
- adding "tools" is expensive
    - Command, SoftwareResult
    - possibly DV2 Classes
    - possibly change to processing profiles
- difficult to know how to find data associated with process
    - often have to look at code to know file paths
- difficult to know how often "tools" are being run
- deadlocking (completely eliminated)

### Indirectly Addressed Legacy System Weaknesses
- difficult to use different storage backends
- data are difficult to secure
    - cannot be made read only because of DV2/symlinks

### Weakness Brainstorm Area
- multiple places to do "orchestration"
    - some "tools" run lots of sub commands & make multiple SoftwareResults
    - makes it difficult to know exactly what work was done in a process
- multiple places to do "work"
    - Models, Builds, SoftwareResults, Commands, etc...
    - difficult to make small changes to a "process"
    - difficult to know what happened during a process
    - much work is "untracked"

## User Stories
### Alignment
- multiple bams as input
- aln twice (read 1 and 2) for each bam
- sampe for each sai pair
- re-header sam file
- sam to bam
- sort bam
- merge sorted bams

### Variant Detection
- mixture of tumor and normal bams as input
- run mutltiple callers
- filter results of each caller
- set operations on result
- filter combined results

### ReferenceAlignment
- multiple bams as input
- group bams into tumor & normal
- align all the bams
- variant detection

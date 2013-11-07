# DSL Experiment

This repo is an exploration of a general DSL for the Genome Modelling System.


## Manifest
* perl/Compiler - translates DSL into a Workflow XML + required inputs list
* perl/Runner - runs Workflow XML given inputs
* perl/Tool - Command objects used by Workflow XML
* \*-definitions - contains re-usable DSL files
* vim - contains vim syntax hilighting files for the DSL


## TODO
- sugar for addressing "A::B::C" with "B::C" or "C"
- forbid recursive imports

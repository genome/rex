set nocursorcolumn
set nocursorline

syntax sync minlines=1 maxlines=1


syn keyword dsl_file_type process
syn keyword dsl_file_type tool

syn keyword dsl_alias is
syn match dsl_type /[A-Z][A-Za-z0-9_]*\(::[A-Z][A-Za-z0-9_]*\)*/

syn keyword dsl_modifier parallel
syn keyword dsl_modifier with

syn keyword dsl_pair_link from
syn match dsl_pair_link /=/
syn match dsl_separator /,/

syn match dsl_string /'\(\\'\|[^']\)*'/
syn match dsl_number /-\?[0-9_]\+\.\?[0-9]*/


hi link dsl_alias Statement
hi link dsl_file_type Include
hi link dsl_modifier Operator
hi link dsl_number Number
hi link dsl_pair_link Statement
hi link dsl_separator Operator
hi link dsl_string String
hi link dsl_type Function

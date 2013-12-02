set nocursorcolumn
set nocursorline

syntax sync minlines=1 maxlines=1


syn keyword dsl_alias is
syn match dsl_type /[A-Z][A-Za-z0-9_]*\(::[A-Z][A-Za-z0-9_]*\)*/
syn match dsl_name /[a-z][A-Za-z0-9_]*/

syn keyword dsl_pair_link from
syn keyword dsl_pair_link to
syn match dsl_external_io /@[a-z][A-Za-z0-9_]*/
syn match dsl_pair_link /=/
syn match dsl_separator /,/

syn match dsl_string /'\(\\'\|[^']\)*'/
syn match dsl_number /-\?[0-9][0-9_]*\(\.[0-9_]*\)\?/


hi link dsl_alias Statement
hi link dsl_external_io Special
hi link dsl_name Identifier
hi link dsl_number Number
hi link dsl_pair_link Statement
hi link dsl_separator Delimiter
hi link dsl_string String
hi link dsl_type Type

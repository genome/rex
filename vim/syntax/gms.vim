set nocursorcolumn
set nocursorline
syntax sync minlines=1 maxlines=1

" This creates a keyword and puts it in the highligh group
syn keyword dsl_keyword with
syn keyword dsl_keyword is
syn keyword dsl_keyword from
syn keyword dsl_keyword process
syn keyword dsl_keyword tool
syn keyword dsl_keyword parallel
" syn keyword dsl_keyword inputs
" syn keyword dsl_keyword outputs

syn match dsl_comma /,/
syn match dsl_type /[A-Z][A-Za-z0-9_]*\(::[A-Z][A-Za-z0-9_]*\)*/
syn match dsl_single_quoted_string /'\(\\'\|[^']\)*'/
" syn match dsl_double_quoted_string /"\(\\"\|[^"]\)*"/
syn match dsl_number /-\?[0-9_]\+\.\?[0-9]*/

hi link dsl_keyword Statement
hi link dsl_type Function
hi link dsl_single_quoted_string String
"hi def dsl_double_quoted_string ctermfg=1
hi link dsl_number Number
hi link dsl_comma Operator

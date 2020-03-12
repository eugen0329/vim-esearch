if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_pythonStatement   False None True
syn keyword es_pythonStatement   as assert break continue del exec global
syn keyword es_pythonStatement   lambda nonlocal pass print return with yield
syn keyword es_pythonStatement   class def nextgroup=es_pythonFunction skipwhite
syn match   es_pythonFunction    "\h\w*" display contained
syn keyword es_pythonConditional elif else if
syn keyword es_pythonRepeat      for while
syn keyword es_pythonOperator    and in is not or
syn keyword es_pythonException   except finally raise try
syn keyword es_pythonInclude     from import
syn keyword es_pythonAsync       async await
syn match   es_pythonComment "#.*$"
syn region  es_pythonString
      \ start=+[uU]\=[rR]\?\z(['"]\)+ end="\z1\|^" skip="\\\\\|\\\z1"
syn region  es_pythonString
      \ start=+[uU]\=[rR]\?\z('''\|"""\)+ end="\z1\|$"

hi def link es_pythonStatement   Statement
hi def link es_pythonFunction    Function
hi def link es_pythonConditional Conditional
hi def link es_pythonRepeat      Repeat
hi def link es_pythonOperator    Operator
hi def link es_pythonException   Exception
hi def link es_pythonInclude     Include
hi def link es_pythonAsync       Statement
hi def link es_pythonComment     Comment
hi def link es_pythonString      String

let b:current_syntax = 'es_ctx_python'

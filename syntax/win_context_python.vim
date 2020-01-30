if exists('b:current_syntax')
  finish
endif

syn keyword pythonStatement   False None True
syn keyword pythonStatement   as assert break continue del exec global
syn keyword pythonStatement   lambda nonlocal pass print return with yield
syn keyword pythonStatement   class def nextgroup=pythonFunction skipwhite
syn match   pythonFunction    "\h\w*" display contained
syn keyword pythonConditional elif else if
syn keyword pythonRepeat      for while
syn keyword pythonOperator    and in is not or
syn keyword pythonException   except finally raise try
syn keyword pythonInclude     from import
syn keyword pythonAsync       async await

syn match   pythonComment "#.*$" contains=pythonTodo,@Spell

syn region  pythonString
      \ start=+[uU]\=[rR]\?\z(['"]\)+ end="\z1" skip="\\\\\|\\\z1"
syn region  pythonString
      \ start=+[uU]\=[rR]\?\z('''\|"""\)+ end="\z1" keepend

hi def link pythonStatement   Statement
hi def link pythonFunction    Function
hi def link pythonConditional Conditional
hi def link pythonRepeat      Repeat
hi def link pythonOperator    Operator
hi def link pythonException   Exception
hi def link pythonInclude     Include
hi def link pythonAsync       Statement
hi def link pythonComment     Comment
hi def link pythonString      String

let b:current_syntax = 'win_context_python'

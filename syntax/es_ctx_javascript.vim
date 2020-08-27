if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_javaScriptConditional if else switch
syn keyword es_javaScriptRepeat      while for do in
syn keyword es_javaScriptBranch      break continue
syn keyword es_javaScriptOperator    new delete instanceof typeof
syn keyword es_javaScriptStatement   return with
syn keyword es_javaScriptNull        null undefined
syn keyword es_javaScriptBoolean     true false
syn keyword es_javaScriptIdentifier  arguments this var let
syn keyword es_javaScriptLabel       case default
syn keyword es_javaScriptException   try catch finally throw
syn keyword es_javaScriptReserved    abstract class const debugger export extends import
syn keyword es_javaScriptFunction    function
syn region  es_javaScriptComment     start="//"  end="$"
syn region  es_javaScriptComment     start="/\*" end="\*/\|^"
syn region  es_javaScriptString      start=+L\="+ skip=+\\\\\|\\"+ end=+"\|^+
syn region  es_javaScriptString      start=+L\='+ skip=+\\\\\|\\'+ end=+'\|^+

hi def link es_javaScriptConditional  Conditional
hi def link es_javaScriptRepeat       Repeat
hi def link es_javaScriptBranch       Conditional
hi def link es_javaScriptOperator     Operator
hi def link es_javaScriptStatement    Statement
hi def link es_javaScriptNull         Keyword
hi def link es_javaScriptBoolean      Boolean
hi def link es_javaScriptIdentifier   Identifier
hi def link es_javaScriptLabel        Label
hi def link es_javaScriptException    Exception
hi def link es_javaScriptReserved     Keyword
hi def link es_javaScriptFunction     Function
hi def link es_javaScriptComment      Comment
hi def link es_javaScriptString       String

let b:current_syntax = 'es_ctx_javascript'

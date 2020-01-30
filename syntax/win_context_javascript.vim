if exists('b:current_syntax')
  finish
endif

syn keyword javaScriptConditional if else switch
syn keyword javaScriptRepeat      while for do in
syn keyword javaScriptBranch      break continue
syn keyword javaScriptOperator    new delete instanceof typeof
syn keyword javaScriptStatement   return with
syn keyword javaScriptNull        null undefined
syn keyword javaScriptBoolean     true false
syn keyword javaScriptIdentifier  arguments this var let

syn keyword javaScriptLabel       case default
syn keyword javaScriptException   try catch finally throw

syn keyword javaScriptReserved    abstract class const debugger export extends import


syn keyword javaScriptFunction  function


syn region javaScriptComment start="//"  end="$"
syn region javaScriptComment start="/\*" end="\*/\|$"

syn region  javaScriptStringD start=+L\="+ skip=+\\\\\|\\"+ end=+"\|$+
syn region  javaScriptStringS start=+L\='+ skip=+\\\\\|\\'+ end=+'\|$+

hi def link javaScriptConditional  Conditional
hi def link javaScriptRepeat       Repeat
hi def link javaScriptBranch       Conditional
hi def link javaScriptOperator     Operator
hi def link javaScriptStatement    Statement
hi def link javaScriptNull         Keyword
hi def link javaScriptBoolean      Boolean
hi def link javaScriptIdentifier   Identifier
hi def link javaScriptLabel        Label
hi def link javaScriptException    Exception
hi def link javaScriptReserved     Keyword
hi def link javaScriptFunction     Function
hi def link javaScriptComment      Comment
hi def link javaScriptStringD      String
hi def link javaScriptStringS      String

let b:current_syntax = 'win_context_javascript'

if exists('b:current_syntax')
  finish
endif

" Reused with copypasting for performance reasons

" copypaste start
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

hi def link es_javaScriptConditional Conditional
hi def link es_javaScriptRepeat      Repeat
hi def link es_javaScriptBranch      Conditional
hi def link es_javaScriptOperator    Operator
hi def link es_javaScriptStatement   Statement
hi def link es_javaScriptNull        Keyword
hi def link es_javaScriptBoolean     Boolean
hi def link es_javaScriptIdentifier  Identifier
hi def link es_javaScriptLabel       Label
hi def link es_javaScriptException   Exception
hi def link es_javaScriptReserved    Keyword
hi def link es_javaScriptFunction    Function
hi def link es_javaScriptComment     Comment
hi def link es_javaScriptString      String
" copypaste end

syn    region es_jsxTag             start=+<[^ ]+ end=+>\|^+ contains=es_jsxAttrib,es_javaScriptString,es_jsxExpressionBlock,es_jsxComponentName
syn    match  es_jsxAttrib          +\s\+\zs\<[^ =]*+ contained
syn    match  es_jsxComponentName   /<[A-Z][^ ]*/ms=s+1 contained
syntax region es_jsxExpressionBlock matchgroup=es_jsxBraces start=+[^)>]\s*\zs\$\={+ end=+}\|^+

hi def link es_jsxTag           Identifier
hi def link es_jsxBraces        Special
hi def link es_jsxAttrib        Type
hi def link es_jsxComponentName Function

let b:current_syntax = 'es_ctx_javascriptreact'

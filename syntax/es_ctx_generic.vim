if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_genericConstant     null nil none NULL NIL NONE Null Nil None
syn keyword es_genericBoolean      true false TRUE FALSE True False
syn keyword es_genericConditional  if unless else elseif case switch select where when default
syn keyword es_genericException    throw raise try catch rescue finally ensure
syn keyword es_genericRepeat       while until for foreach do
syn keyword es_genericScopeDecl    public  protected private abstract global shared
syn keyword es_genericInclude      include import use require package native
syn keyword es_genericOperator     new delete as in
syn keyword es_genericStatement    break next continue return goto begin end
syn keyword es_genericKeyword      var let this self super yield implement[s] extend[s]
syn keyword es_genericStorageClass const mutable static register volatile
syn keyword es_genericStructure    struct class module export union enum interface typedef

syn keyword es_genericKeyword      func function fn def nextgroup=es_genericFunction skipwhite
syn match   es_genericFunction     "\h\w*" contained

syn match  es_genericComment "//.*"
syn match  es_genericComment "#.*"
syn region es_genericComment start="/\*" end="\*/\|$"
syn region es_genericString  start=/"/ skip=/\\\\\|\\"/ end=/"\|^/
syn region es_genericString  start=/'/ skip=/\\\\\|\\'/ end=/'\|^/

hi def link es_genericConstant     Constant
hi def link es_genericBoolean      Boolean
hi def link es_genericConditional  Conditional
hi def link es_genericException    Exception
hi def link es_genericRepeat       Repeat
hi def link es_genericScopeDecl    StorageClass
hi def link es_genericInclude      Include
hi def link es_genericOperator     Operator
hi def link es_genericStatement    Statement
hi def link es_genericKeyword      Keyword
hi def link es_genericStorageClass StorageClass
hi def link es_genericStructure    Structure
hi def link es_genericComment      Comment
hi def link es_genericString       String
hi def link es_genericFunction     Function

let b:current_syntax = 'es_ctx_generic'

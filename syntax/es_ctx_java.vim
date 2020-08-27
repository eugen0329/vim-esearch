if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_javaConditional  if else switch
syn keyword es_javaRepeat       while for do
syn keyword es_javaBoolean      true false
syn keyword es_javaConstant     null
syn keyword es_javaTypedef      this super
syn match   es_javaTypedef      "\.\s*\<class\>"ms=s+1
syn keyword es_javaOperator     new instanceof
syn keyword es_javaStatement    return
syn keyword es_javaStorageClass static synchronized transient volatile final strictfp serializable
syn keyword es_javaExceptions   throw try catch finally
syn keyword es_javaAssert       assert
syn keyword es_javaClassDecl    extends implements interface
syn match   es_javaClassDecl    "@interface\>"
syn keyword es_javaClassDecl    enum
syn keyword es_javaScopeDecl    public protected private abstract

syn region  es_javaComment start="//"  end="$"
syn region  es_javaComment start="/\*" end="\*/\|^"
syn region  es_javaString  start=+L\="+ skip=+\\\\\|\\"+ end=+"\|^+

hi def link es_javaConditional  Conditional
hi def link es_javaRepeat       Repeat
hi def link es_javaBoolean      Boolean
hi def link es_javaConstant     Constant
hi def link es_javaTypedef      Typedef
hi def link es_javaOperator     Operator
hi def link es_javaStatement    Statement
hi def link es_javaStorageClass StorageClass
hi def link es_javaExceptions   Exception
hi def link es_javaAssert       Statement
hi def link es_javaClassDecl    StorageClass
hi def link es_javaScopeDecl    StorageClass
hi def link es_javaComment      Comment
hi def link es_javaString       String

let b:current_syntax = 'es_ctx_java'

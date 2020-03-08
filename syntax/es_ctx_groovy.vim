if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_groovyExternal     native package
syn match   es_groovyExternal     "\<import\>\(\s\+static\>\)\?"
syn keyword es_groovyError        goto const
syn keyword es_groovyConditional  if else switch
syn keyword es_groovyRepeat       while for do
syn keyword es_groovyBoolean      true false
syn keyword es_groovyConstant     null
syn keyword es_groovyTypedef      this super
syn match   es_groovyTypedef      "\.\s*\<class\>"ms=s+1
syn keyword es_groovyOperator     new instanceof
syn keyword es_groovyStatement    return
syn keyword es_groovyExceptions   throw try catch finally

syn keyword es_groovyJDKBuiltin   as def in
syn keyword es_groovyJDKOperOverl div minus plus abs round power multiply
syn keyword es_groovyJDKMethods   each call inject sort print println
syn keyword es_groovyJDKMethods   getAt putAt size push pop toList getText writeLine eachLine readLines
syn keyword es_groovyJDKMethods   withReader withStream withWriter withPrintWriter write read leftShift
syn keyword es_groovyJDKMethods   withWriterAppend readBytes splitEachLine
syn keyword es_groovyJDKMethods   newInputStream newOutputStream newPrintWriter newReader newWriter
syn keyword es_groovyJDKMethods   compareTo next previous isCase
syn keyword es_groovyJDKMethods   times step toInteger upto any collect dump every find findAll grep
syn keyword es_groovyJDKMethods   inspect invokeMethods join
syn keyword es_groovyJDKMethods   getErr getIn getOut waitForOrKill
syn keyword es_groovyJDKMethods   count tokenize asList flatten immutable intersect reverse reverseEach
syn keyword es_groovyJDKMethods   subMap append asWritable eachByte eachLine eachFile

syn region  es_groovyString       start=+"+ end=+"+ end=+$+
syn region  es_groovyString       start=+'+ end=+'+ end=+$+
syn region  es_groovyString       start=+"""+ end=+"""+ end=+$+
syn region  es_groovyString       start=+'''+ end=+'''+ end=+$+

syn match   es_groovyComment      "/\*\*/"
syn region  es_groovyComment      start="/\*"  end="\*/\|^"

" martinda/Jenkinsfile-vim-syntax
syn keyword es_jenkinsfileCoreStep checkout docker node scm sh stage parallel steps step tool post always changed failure success unstable aborted

hi def link es_groovyExternal      Include
hi def link es_groovyError         Error
hi def link es_groovyConditional   Conditional
hi def link es_groovyRepeat        Repeat
hi def link es_groovyBoolean       Boolean
hi def link es_groovyConstant      Constant
hi def link es_groovyTypedef       Typedef
hi def link es_groovyOperator      Operator
hi def link es_groovyType          Type
hi def link es_groovyStatement     Statement
hi def link es_groovyStorageClass  StorageClass
hi def link es_groovyExceptions    Exception
hi def link es_groovyJDKBuiltin    Special
hi def link es_groovyJDKOperOverl  Operator
hi def link es_groovyJDKMethods    Function
hi def link es_groovyString        String
hi def link es_groovyComment       Comment
hi def link es_jenkinsfileCoreStep Function

let b:current_syntax = 'es_ctx_groovy'

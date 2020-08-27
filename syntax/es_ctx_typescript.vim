if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_typescriptImport             from as import
syn keyword es_typescriptExport             export
syn keyword es_typescriptModule             namespace module
syn keyword es_typescriptPrototype          prototype
syn keyword es_typescriptCastKeyword        as
syn keyword es_typescriptIdentifier         arguments this super
syn keyword es_typescriptKeywordOp          in instanceof
syn keyword es_typescriptOperator           delete new typeof void
syn keyword es_typescriptForOperator        in of
syn keyword es_typescriptBoolean            true false
syn keyword es_typescriptNull               null undefined
syn keyword es_typescriptGlobal             self top parent global process console Buffer module exports setTimeout clearTimeout setInterval clearInterval
syn keyword es_typescriptConditional        if else switch break continue case default
syn keyword es_typescriptRepeat             do while for
syn keyword es_typescriptStatementKeyword   with yield return
syn keyword es_typescriptTry                try
syn keyword es_typescriptExceptions         catch throw finally
syn keyword es_typescriptDebugger           debugger
syn keyword es_typescriptAmbientDeclaration declare
syn keyword es_typescriptKeyword            interface class function extends implements await alert confirm prompt status keyof
syn keyword es_typescriptAbstract           abstract
syn keyword es_typescriptVariable           let var const
syn keyword es_typescriptAliasKeyword       type nextgroup=es_typescriptAliasDeclaration skipwhite
syn keyword es_typescriptEnumKeyword        enum
syn match   es_typescriptAliasDeclaration   / [^=]\+/ contained
syn match   es_typescriptFuncName           / \zs\K\k*\ze\s*(/ nextgroup=es_typescriptCall skipwhite
syn region  es_typescriptCall               start=/(/hs=e+1 end=/)/he=s-1 end=/^/ contained
syn match   es_typescriptTypeReference      /\K\k*\(\.\K\k*\)*/ contained
syn match   es_typescriptDecorator          /@\([_$a-zA-Z][_$a-zA-Z0-9]*\.\)*[_$a-zA-Z][_$a-zA-Z0-9]*\>/
syn region  es_typescriptString             start=+\z(["']\)+  skip=+\\\%(\z1\|$\)+  end=+\z1+ end=+^+
syn match   es_typescriptLineComment        "//.*"
syn region  es_typescriptComment            start="/\*" end="\*/" end="^"

hi def link es_typescriptVariable           Identifier
hi def link es_typescriptEnumKeyword        Identifier
hi def link es_typescriptAliasDeclaration   Identifier
hi def link es_typescriptTypeReference      Identifier
hi def link es_typescriptKeywordOp          Identifier
hi def link es_typescriptOperator           Identifier
hi def link es_typescriptForOperator        Repeat
hi def link es_typescriptRepeat             Repeat
hi def link es_typescriptImport             Special
hi def link es_typescriptExport             Special
hi def link es_typescriptModule             Special
hi def link es_typescriptCastKeyword        Special
hi def link es_typescriptDecorator          Special
hi def link es_typescriptTry                Special
hi def link es_typescriptExceptions         Special
hi def link es_typescriptAmbientDeclaration Special
hi def link es_typescriptAbstract           Special
hi def link es_typescriptBoolean            Boolean
hi def link es_typescriptNull               Boolean
hi def link es_typescriptConditional        Conditional
hi def link es_typescriptPrototype          Type
hi def link es_typescriptIdentifier         Structure
hi def link es_typescriptGlobal             Constant
hi def link es_typescriptStatementKeyword   Statement
hi def link es_typescriptFuncName           Function
hi def link es_typescriptCall               PreProc
hi def link es_typescriptString             String
hi def link es_typescriptLineComment        Comment
hi def link es_typescriptComment            Comment
hi def link es_typescriptTypeQuery          Keyword
hi def link es_typescriptKeyword            Keyword
hi def link es_typescriptAliasKeyword       Keyword

let b:current_syntax = 'es_ctx_typescript'

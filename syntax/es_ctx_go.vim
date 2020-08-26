if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_goDirective   package import
syn keyword es_goDeclaration var const type func
syn keyword es_goDeclType    struct interface
syn keyword es_goStatement   defer go goto return break continue fallthrough
syn keyword es_goConditional if else switch select
syn keyword es_goLabel       case default
syn keyword es_goRepeat      for range
syn keyword es_goBuiltins  append cap close complex copy delete imag len make new panic print println real recover
syn keyword es_goConstants iota nil
syn keyword es_goBool true false 
syn keyword es_goType      chan map bool string error int int8 int16 int32 int64 rune byte uint uint8 uint16 uint32 uint64 uintptr float32 float64 complex64 complex128

syn region  es_goString      start=+"+   skip=+\\\\\|\\"+ end=+"\|^+
syn region  es_goRawString   start=+`+   end=+`\|$+
syn region  es_goComment     start="/\*" end="\*/\|^"
syn region  es_goComment     start="//"  end="$"


hi def link es_goDirective   Statement
hi def link es_goDeclaration Keyword
hi def link es_goDeclType    Keyword
hi def link es_goConstants   Keyword
hi def link es_goBool        Boolean
hi def link es_goType        Type
hi def link es_goBuiltins    Keyword
hi def link es_goStatement   Statement
hi def link es_goConditional Conditional
hi def link es_goLabel       Label
hi def link es_goRepeat      Repeat
hi def link es_goString      String
hi def link es_goRawString   String
hi def link es_goComment     Comment

let b:current_syntax = 'es_ctx_go'

if exists('b:current_syntax')
  finish
endif

syn keyword goDirective   package import
syn keyword goDeclaration var const type func
syn keyword goDeclType    struct interface
syn keyword goStatement   defer go goto return break continue fallthrough
syn keyword goConditional if else switch select
syn keyword goLabel       case default
syn keyword goRepeat      for range

syn region goString    start=+"+   skip=+\\\\\|\\"+ end=+"\|$+
syn region goRawString start=+`+   end=+`\|$+
syn region goComment   start="/\*" end="\*/\|$"
syn region goComment   start="//"  end="$"

hi def link     goDirective         Statement
hi def link     goDeclaration       Keyword
hi def link     goDeclType          Keyword
hi def link     goStatement         Statement
hi def link     goConditional       Conditional
hi def link     goLabel             Label
hi def link     goRepeat            Repeat
hi def link     goString            String
hi def link     goRawString         String
hi def link     goComment           Comment

let b:current_syntax = 'win_context_go'

if exists('b:current_syntax')
  finish
endif

syn match   shDerefSimple "\$\%(\h\w*\|\d\)"
syn keyword shKeyword     case esac do done for in if fi until while

syn region  shSingleQuote start=+'+ end=+'\|$+
syn region  shDoubleQuote start=+\%(\%(\\\\\)*\\\)\@<!"+ skip=+\\"+ end=+"\|$+

hi def link shDerefSimple PreProc
hi def link shSingleQuote String
hi def link shDoubleQuote String
hi def link shKeyword     Keyword

let b:current_syntax = 'win_context_sh'

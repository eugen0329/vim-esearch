if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_shStatement   break cd chdir continue eval exec exit kill newgrp pwd read readonly return shift test trap ulimit umask wait
syn match   es_shDerefSimple "\$\%(\h\w*\|\d\)"
syn keyword es_shKeyword     case esac do done for in if fi until while
syn keyword es_shSetList     declare local export set unset
syn region  es_shSingleQuote start=+'+ end=+'\|$+
syn region  es_shDoubleQuote start=+\%(\%(\\\\\)*\\\)\@<!"+ skip=+\\"+ end=+"\|^+ contains=es_shDerefSimple

hi def link es_shStatement   Statement
hi def link es_shDerefSimple PreProc
hi def link es_shSingleQuote String
hi def link es_shDoubleQuote String
hi def link es_shKeyword     Keyword
hi def link es_shSetList     Identifier

let b:current_syntax = 'es_ctx_sh'

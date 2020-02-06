if exists('b:current_syntax')
  finish
endif

syn keyword es_cStatement    goto break return continue asm
syn keyword es_cLabel        case default
syn keyword es_cConditional  if else switch
syn keyword es_cRepeat       while for do
syn keyword es_cStructure    struct union enum typedef
syn keyword es_cStorageClass static register auto volatile extern const
syn region  es_cComment       start="//"  end="$"
syn region  es_cComment       start="/\*" end="\*/\|$"
syn region  es_cString       start=+L\="+ skip=+\\\\\|\\"+ end=+"\|$+
" todo test
syn match   es_cDefine        '#\(define\|undef\|if\|ifdef\|ifndef\)\>'
syn match   es_cPreProc       '#\(pragma\|line\|warning\|warn\|error\)\>'

hi def link es_cStatement    Statement
hi def link es_cLabel        Label
hi def link es_cConditional  Conditional
hi def link es_cRepeat       Repeat
hi def link es_cStructure    Structure
hi def link es_cStorageClass StorageClass
hi def link es_cComment      Comment
hi def link es_cString       String
hi def link es_cDefine       Macro
hi def link es_cPreProc      PreProc

let b:current_syntax = 'win_context_c'

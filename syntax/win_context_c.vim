if exists('b:current_syntax')
  finish
endif

syn keyword cStatement    goto break return continue asm
syn keyword cLabel        case default
syn keyword cConditional  if else switch
syn keyword cRepeat       while for do
syn keyword cStructure    struct union enum typedef
syn keyword cStorageClass static register auto volatile extern const

syn region cCommentL start="//"  end="$"
syn region cComment  start="/\*" end="\*/\|$"

syn match cSpecial display contained "\\\(x\x\+\|\o\{1,3}\|.\|$\)"
if !exists("c_no_utf")
  syn match cSpecial  display contained "\\\(u\x\{4}\|U\x\{8}\)"
endif
syn region  cString start=+L\="+ skip=+\\\\\|\\"+ end=+"\|$+ contains=cSpecial extend

syn match  cDefine   '#\(define\|undef\)\>'
syn match  cPreProc   '#\(pragma\|line\|warning\|warn\|error\)\>'

hi def link cStatement    Statement
hi def link cLabel        Label
hi def link cConditional  Conditional
hi def link cRepeat       Repeat
hi def link cStructure    Structure
hi def link cStorageClass StorageClass
hi def link cCommentL     Comment
hi def link cComment      Comment
hi def link cString       String
hi def link cDefine       Macro
hi def link cPreProc      PreProc

let b:current_syntax = 'win_context_c'

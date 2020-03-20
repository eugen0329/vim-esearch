if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_cStatement    goto break return continue asm
syn keyword es_cLabel        case default
syn keyword es_cConditional  if else switch
syn keyword es_cRepeat       while for do
syn keyword es_cStructure    struct union enum typedef class typename template namespace
syn keyword es_cStorageClass static register auto volatile extern const mutable
syn keyword es_cType         int long short char void signed unsigned float double
syn region  es_cComment      start="//"  end="$"
syn region  es_cComment      start="/\*" end="\*/\|^"
syn region  es_cString       start=+"+ skip=+\\\\\|\\"+ end=+"\|^+
syn match   es_cDefine       '#\s*\(define\|undef\|if\|ifdef\|ifndef\)\>'
syn match   es_cPreProc      '#\s*\(pragma\|line\|warning\|warn\|error\)\>'

" cpp definitions
syn keyword es_cStatement  new delete this friend using public protected private
syn keyword es_cType       inline virtual explicit export
syn keyword es_cType       bool wchar_t
syn keyword es_cExceptions throw try catch
syn keyword es_cOperator   operator typeid
syn keyword es_cOperator   and bitor or xor compl bitand and_eq or_eq xor_eq not not_eq
syn keyword es_cBoolean    true false

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
hi def link es_cType         Type
hi def link es_cExceptions   Exception
hi def link es_cOperator     Operator
hi def link es_cBoolean      Boolean

let b:current_syntax = 'es_ctx_c'

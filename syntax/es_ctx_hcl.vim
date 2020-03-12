if exists('b:current_syntax')
  finish
endif

" partially based and made coherent with vim-syntax-terraform

syn match  es_hclSection      /\w\+\ze\s\+[{"]/
syn match  es_hclBraces       /[\[\]]/
syn region es_hclValueString  start=/"/   skip=/\\\+"/ end=/"\|^/ contains=es_hclStringInterp
syn region es_hclStringInterp start=/\${/ end=/}/      contained
syn region es_hclComment      start="/\*" end="\*/\|^"
syn match  es_hclComment      "#.*"
syn match  es_hclComment      "//.*"

syn keyword es_hclContent        content
syn keyword es_hclRepeat         for in
syn keyword es_hclConditional    if
syn keyword es_hclPrimitiveType  string bool number
syn keyword es_hclStructuralType object tuple
syn keyword es_hclCollectionType list map set
syn keyword es_hclValueNull      null

hi def link es_hclSection        Structure
hi def link es_hclBraces         Delimiter
hi def link es_hclValueString    String
hi def link es_hclStringInterp   Identifier
hi def link es_hclComment        Comment
hi def link es_hclContent        Structure
hi def link es_hclRepeat         Repeat
hi def link es_hclConditional    Conditional
hi def link es_hclPrimitiveType  Type
hi def link es_hclStructuralType Type
hi def link es_hclCollectionType Type
hi def link es_hclValueNull      Constant

let b:current_syntax = 'es_ctx_hcl'

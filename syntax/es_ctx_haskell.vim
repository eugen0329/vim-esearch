if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax
syn match   es_hsModule      "module"
syn match   es_hsImport      "import.*"he=s+6 contains=es_hsImportMod,es_hsLineComment,es_hsBlockComment
syn region  es_hsString      start=+"+  skip=+\\\\\|\\"+  end=+"\|^+
syn keyword es_hsImportMod   as qualified hiding contained
syn keyword es_hsInfix       infix infixl infixr
syn keyword es_hsStructure   class data deriving instance default where
syn keyword es_hsTypedef     type newtype
syn keyword es_hsStatement   do case of let in
syn keyword es_hsConditional if then else
syn keyword es_hsDebug     undefined error trace

syn match   es_hsLineComment  "---*\([^-!#$%&\*\+./<=>\?@\\^|~].*\)\?$"
syn region  es_hsBlockComment start="{-"  end="-}\|^"
syn region  es_hsPragma       start="{-#" end="#-}\|^"
syn match   es_hsCharacter    "[^a-zA-Z0-9_']'\([^\\]\|\\[^']\+\|\\'\)'"lc=1

hi def link es_hsModule       Structure
hi def link es_hsImport       Include
hi def link es_hsString       String
hi def link es_hsImportMod    Include
hi def link es_hsInfix        PreProc
hi def link es_hsStructure    Structure
hi def link es_hsTypedef      Typedef
hi def link es_hsStatement    Statement
hi def link es_hsConditional  Conditional
hi def link es_hsLineComment  Comment
hi def link es_hsBlockComment Comment
hi def link es_hsPragma       SpecialComment
hi def link es_hsCharacter    Character
hi def link es_hsDebug        Debug

let b:current_syntax = 'es_ctx_haskell'

if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_scalaKeyword             catch do else final finally for forSome if match return throw try while yield macro case
syn keyword es_scalaKeyword             class trait object extends with nextgroup=es_scalaInstanceDeclaration skipwhite
syn keyword es_scalaKeyword             type nextgroup=es_scalaTypeDeclaration2 skipwhite
syn keyword es_scalaKeyword             val nextgroup=es_scalaNameDefinition skipwhite
syn keyword es_scalaKeyword             def var nextgroup=es_scalaNameDefinition skipwhite
syn keyword es_scalaSpecial             shouldBe when goto using startWith initialize onTransition stay become unbecome this true false ne eq
syn keyword es_scalaSpecial             new nextgroup=es_scalaInstanceDeclaration skipwhite
syn match   es_scalaSpecial             "\%(<-\|->\)"
syn keyword es_scalaKeywordModifier     abstract override final lazy implicit implicitly private protected sealed null require super
syn keyword es_scalaExternal            package import

syn match   es_scalaInstanceDeclaration /\<[_\.A-Za-z0-9$]\+\>/ contained
syn match   es_scalaNameDefinition      /\<[_A-Za-z0-9$]\+\>/ contained
syn match   es_scalaCapitalWord         /\<[A-Z][A-Za-z0-9$]*\>/
syn match   es_scalaTypeDeclaration     /:\s\+\zs[^),=]\+/ nextgroup=es_scalaTypeExtension
syn match   es_scalaTypeExtension       /)\?\s*\zs\%(=>\|<:\|:>\|=:=\|::\|#\)/ contained nextgroup=es_scalaTypeDeclaration2 skipwhite
syn match   es_scalaTypeDeclaration2    /\w\+/ contained nextgroup=es_scalaTypeExtension
syn region  es_scalaString              start=+"+   skip=+\\\\\|\\"+ end=+"\|^+
syn region  es_scalaMultilineComment    start="/\*" end="\*/\|^"
syn match   es_scalaTrailingComment     "//.*$"
syn region  es_scalaCommentCodeBlock    start="{{{" end="}}}\|^"

hi def link es_scalaTypeExtension       Keyword
hi def link es_scalaTypeDeclaration     Type
hi def link es_scalaTypeDeclaration2    Type
hi def link es_scalaKeyword             Keyword
hi def link es_scalaSpecial             PreProc
hi def link es_scalaKeywordModifier     Function
hi def link es_scalaExternal            Include
hi def link es_scalaInstanceDeclaration Special
hi def link es_scalaNameDefinition      Function
hi def link es_scalaCapitalWord         Special
hi def link es_scalaString              String
hi def link es_scalaMultilineComment    Comment
hi def link es_scalaTrailingComment     Comment
hi def link es_scalaCommentCodeBlock    String

let b:current_syntax = 'es_ctx_scala'

if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn region  es_htmlString   contained start=+"+ end=+"\|$+
syn region  es_htmlString   contained start=+'+ end=+'\|$+
syn region  es_htmlEndTag             start=+</+      end=+>\|$+ contains=es_htmlTagN
syn region  es_htmlTag                start=+<[^/]+   end=+>\|$+ contains=es_htmlTagN,es_htmlString keepend
syn match   es_htmlTagName "\h[-\w]*"
syn match   es_htmlTagN    contained +<\s*[-a-zA-Z0-9]\++hs=s+1  contains=es_htmlTagName
syn match   es_htmlTagN    contained +</\s*[-a-zA-Z0-9]\++hs=s+2 contains=es_htmlTagName

hi def link es_htmlString  String
hi def link es_htmlEndTag  Identifier
hi def link es_htmlTag     Function
hi def link es_htmlTagName Statement

let b:current_syntax = 'es_ctx_html'

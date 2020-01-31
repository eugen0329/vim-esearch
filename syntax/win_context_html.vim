if exists('b:current_syntax')
  finish
endif

syn region  htmlString   contained start=+"+ end=+"\|$+
syn region  htmlString   contained start=+'+ end=+'\|$+
syn region  htmlEndTag             start=+</+      end=+>\|$+ contains=htmlTagN
syn region  htmlTag                start=+<[^/]+   end=+>\|$+ fold contains=htmlTagN,htmlString keepend

syn match htmlTagName "\h[-\w]*"
" hs	Highlight Start	offset for where the highlighting starts
syn match htmlTagN    contained +<\s*[-a-zA-Z0-9]\++hs=s+1  contains=htmlTagName
syn match htmlTagN    contained +</\s*[-a-zA-Z0-9]\++hs=s+2 contains=htmlTagName

hi def link htmlString  String
hi def link htmlEndTag  Identifier
hi def link htmlTag     Function
hi def link htmlTagName Statement

let b:current_syntax = 'win_context_html'

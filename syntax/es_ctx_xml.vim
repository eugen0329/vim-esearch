if exists('b:current_syntax')
  finish
endif

syn region es_xmlTag              start=+<[^ ]+   end=+>\|^+ contains=es_xmlAttrib,es_xmlString
syn region es_xmlProcessing       matchgroup=es_xmlProcessingDelim start="<?" end="?>" contains=es_xmlString,es_xmlProcessingAttrib
syn region es_xmlEndTag           start=+</[^ ]+   end=+>\|^+
syn match  es_xmlAttrib           +[^ =]\+\ze\s*=+ contained
syn match  es_xmlProcessingAttrib "[^ =]\+" contained
syn region es_xmlString           start=+\z(["']\)+  skip=+\\\\\|\\\z1+  end=+\z1\|^+ keepend contained
syn region es_xmlComment          start=+<!+ end=+>\|^+

hi def link es_xmlTag              Function
hi def link es_xmlProcessingDelim  Comment
hi def link es_xmlEndTag           Identifier
hi def link es_xmlAttrib           Type
hi def link es_xmlProcessingAttrib Type
hi def link es_xmlString           String
hi def link es_xmlComment          Comment

let b:current_syntax = 'es_ctx_xml'

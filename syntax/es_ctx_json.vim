if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_jsonBoolean  true false
syn keyword es_jsonNull     null
syn match es_jsonBraces      /[{}\[\]]/
syn match es_jsonString      /"\([^"]\|\\\"\)\+[[:blank:]"\n\r]/hs=s+1,he=e-1
syn match es_jsonKeyword     /"\([^"]\|\\\"\)\+["[:blank:]\r\n]*\ze\:/hs=s+1,he=e-1

hi def link es_jsonBoolean Boolean
hi def link es_jsonNull    Function
hi def link es_jsonKeyword Label
hi def link es_jsonString  String
hi def link es_jsonBraces  Delimiter

let b:current_syntax = 'es_ctx_json'

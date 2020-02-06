if exists('b:current_syntax')
  finish
endif

exe 'syntax include @main syntax/' . b:__esearch_preview_filetype__ . '.vim'
unlet b:__esearch_preview_filetype__
if exists('b:current_syntax')
  unlet b:current_syntax
endif

syn match esearchPreviewLineNr '^\s*\d\+\s'  nextgroup=esearchPreviewContent
syn match esearchPreviewLineNr '^\s*->\s*\d\+\s' nextgroup=esearchPreviewContent contains=esearchPreviewSign
syn match esearchPreviewSign '->' contained
syn region esearchPreviewContent start='.' end='$' contained oneline keepend excludenl contains=@main

hi def link esearchPreviewLineNr LineNr
hi def link esearchPreviewSign CursorLineNr

let b:current_syntax = 'esearchPreview'

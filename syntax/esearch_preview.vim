if exists('b:current_syntax')
  finish
endif

syn match esearchPreviewLineNr '^\s*\d\+\s'  nextgroup=esearchPreviewMain
syn match esearchPreviewLineNr '^\s*->\s*\d\+\s' nextgroup=esearchPreviewMain contains=esearchPreviewSign
syn match esearchPreviewSign '->' contained

let b:__esearch_preview_filetype__ = 'c'
if exists('b:__esearch_preview_filetype__')
  try
    exe 'syntax include @main syntax/' . b:__esearch_preview_filetype__ . '.vim'
    if exists('b:current_syntax')
      unlet b:current_syntax
    endif

    syn region esearchPreviewMain start='.' end='$' contained oneline keepend excludenl contains=@main
  catch /Vim(syntax):E484/
    " filetype exists, but syntax don't
    syn region esearchPreviewMain start='.' end='$' contained oneline keepend excludenl
  finally
    unlet b:__esearch_preview_filetype__
  endtry
else
  syn region esearchPreviewMain start='.' end='$' contained oneline keepend excludenl
endif


hi def link esearchPreviewLineNr LineNr
hi def link esearchPreviewSign CursorLineNr

let b:current_syntax = 'esearchPreview'

if exists('b:current_syntax')
  finish
endif

if !g:esearch.win_ui_nvim_syntax
  syn match esearchLineNr     '^\s\+[+^]\=\s*\d\+\s'
  syn match esearchFilename   '^[^ ].*$'
  syn match esearchHeader     '\%1l.*' contains=esearchStatistics
  syn match esearchStatistics '\d\+' contained
  syn match esearchDiffAdd    '^\s\+\zs[+^]' contained containedin=esearchLineNr
endif

let b:current_syntax = 'esearch'

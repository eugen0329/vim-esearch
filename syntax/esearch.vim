if exists('b:current_syntax')
  finish
endif

if !g:esearch.win_ui_nvim_syntax
  syn match esearchLineNr     '^\s\+[+^_]\=\s*\d\+\s'
  syn match esearchDiffAdd    '^\s\+\zs[+^_]' contained containedin=esearchLineNr
  syn match esearchFilename   '^[^ ].*$'
  syn match esearchHeader     '\%1l.*'
  syn match esearchStatistics '\d\+' contained containedin=esearchHeader
endif

let b:current_syntax = 'esearch'

if exists('b:current_syntax')
  finish
endif

syn region esearchHeader   start='\%1l'       end='$' oneline
syn region esearchFilename start='\%>2l^[^ ]' end='$' oneline
syn match  esearchLineNr   '^\s\+\d\+'

hi def link esearchHeader   Title
hi def link esearchFilename Directory
hi def link esearchLineNr   LineNr

call esearch#util#copy_highlight('esearchMatch', 'MoreMsg', {
      \ 'overrides': {
      \   'force': {
      \     'ctermbg': esearch#util#highlight_attr('CursorLine', 'ctermbg'),
      \     'guibg':   esearch#util#highlight_attr('CursorLine', 'guibg'),
      \     'cterm':  'bold',
      \     'gui':    'bold',
      \   },
      \ },
      \ 'options': { 'default': 1 }
      \ })

if exists('b:esearch_ellipsis')
  hi def link esearchEllipsis WarningMsg
  exe 'syn match esearchEllipsis "\%(^\%>3l\s\+\d\+\s\)\@<=\V' . b:esearch_ellipsis . '"'
  exe 'syn match esearchEllipsis "\V'. b:esearch_ellipsis . '\$"'
endif

" legacy
if hlexists('esearchLnum')
  call esearch#util#copy_highlight('esearchLineNr', 'esearchLnum', {'command_options': { 'force': 1 }})
endif
if hlexists('esearchFName')
  call esearch#util#copy_highlight('esearchFilename', 'esearchFName', {'command_options': { 'force': 1 }})
endif
if hlexists('ESearchMatch')
  call esearch#util#copy_highlight('ESearchMatch', 'esearchMatch', {'command_options': { 'force': 1 }})
endif

let b:current_syntax = 'esearch'

if exists('b:current_syntax')
  finish
endif

syn region esearchHeader   start='\%1l'       end='$' oneline
syn region esearchFilename start='\%>2l^[^ ]' end='$' oneline
syn match  esearchLineNr   '^\s\+\d\+'

hi def link esearchHeader   Title
hi def link esearchFilename Directory
hi def link esearchLineNr   LineNr

let s:cursorline    = esearch#util#highlight_attritbutes('CursorLine')
let s:esearch_match = extend(esearch#util#highlight_attritbutes('MoreMsg'), {
      \   'ctermbg': s:cursorline.ctermbg,
      \   'guibg':   s:cursorline.guibg,
      \   'cterm':  'bold',
      \   'gui':    'bold',
      \ })
call esearch#util#set_highlight('esearchMatch', s:esearch_match, {'default': 1})
unlet s:esearch_match s:cursorline

if exists('b:esearch_ellipsis')
  hi def link esearchEllipsis WarningMsg
  exe 'syn match esearchEllipsis "\%(^\%>3l\s\+\d\+\s\)\@<=\V' . b:esearch_ellipsis . '"'
  exe 'syn match esearchEllipsis "\V'. b:esearch_ellipsis . '\$"'
endif

" legacy names support
if hlexists('esearchLnum')
  call esearch#util#copy_highlight('esearchLineNr', 'esearchLnum', {'force': 1})
endif
if hlexists('esearchFName')
  call esearch#util#copy_highlight('esearchFilename', 'esearchFName', {'force': 1})
endif
if hlexists('ESearchMatch')
  call esearch#util#copy_highlight('ESearchMatch', 'esearchMatch', {'force': 1})
endif

let b:current_syntax = 'esearch'

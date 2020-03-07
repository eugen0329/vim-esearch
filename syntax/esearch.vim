if exists('b:current_syntax')
  finish
endif

if !has('nvim')
  syn match esearchHeader   '\%1l.*'
endif
syn match esearchFilename '^[^ ]\+$'
syn match esearchLineNr   '^\s\+\d\+\s'

hi def link esearchHeader       Title
hi def link esearchFilename     Directory
hi def link esearchLineNr       LineNr
hi def link esearchCursorLineNr CursorLineNr

let s:cursorline    = esearch#util#get_highlight('CursorLine')
let s:esearch_match = extend(esearch#util#get_highlight('MoreMsg'), {
      \   'ctermbg': get(s:cursorline, 'ctermbg', 239),
      \   'guibg':   get(s:cursorline, 'guibg',   '#005FFF'),
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

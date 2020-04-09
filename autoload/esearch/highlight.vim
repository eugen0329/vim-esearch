" Functions to handle clearing syntax on changing colorschemes or reloading
" $MYVIMRC

fu! esearch#highlight#init() abort
  augroup esearch#highlight
    au!
    au ColorScheme * call esearch#highlight#define()
  augroup END
endfu

fu! esearch#highlight#define() abort
  hi def link esearchHeader       Title
  hi def link esearchFilename     Directory
  hi def link esearchLineNr       LineNr
  hi def link esearchCursorLineNr CursorLineNr

  let cursorline    = esearch#util#get_highlight('CursorLine')
  let esearch_match = extend(esearch#util#get_highlight('MoreMsg'), {
        \   'ctermbg': get(cursorline, 'ctermbg', 239),
        \   'guibg':   get(cursorline, 'guibg',   '#005FFF'),
        \   'cterm':  'bold,underline',
        \   'gui':    'bold,underline',
        \ })
  call esearch#util#set_highlight('esearchMatch', esearch_match, {'default': 1})

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
endfu

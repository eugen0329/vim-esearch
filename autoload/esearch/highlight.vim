let s:Highlight = vital#esearch#import('Vim.Highlight')

" Functions to handle clearing syntax on changing colorschemes or reloading
" $MYVIMRC

fu! esearch#highlight#init() abort
  aug esearch_highlight
    au!
    au ColorScheme * call esearch#highlight#define()
  aug END
endfu

fu! esearch#highlight#define() abort
  hi def link esearchHeader       Title
  hi def link esearchStatistics   Number
  hi def link esearchFilename     Directory
  hi def link esearchLineNr       LineNr
  hi def link esearchCursorLineNr CursorLineNr

  let cursorline    = s:get('CursorLine')
  let esearch_match = extend(s:get('MoreMsg'), {
        \   'ctermbg': get(cursorline, 'ctermbg', 239),
        \   'guibg':   get(cursorline, 'guibg',   '#005FFF'),
        \   'cterm':  'bold,underline',
        \   'gui':    'bold,underline',
        \ })
  call s:set('esearchMatch', esearch_match, {'default': 1})

  " legacy names support
  if hlexists('esearchLnum')
    call s:copy('esearchLineNr', 'esearchLnum', {'force': 1})
  endif
  if hlexists('esearchFName')
    call s:copy('esearchFilename', 'esearchFName', {'force': 1})
  endif
  if hlexists('ESearchMatch')
    call s:copy('ESearchMatch', 'esearchMatch', {'force': 1})
  endif
endfu

fu! s:copy(from, to, options) abort
  let new_highlight = {'name': a:from, 'attrs': s:Highlight.get(a:to).attrs}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:set(name, attributes, options) abort
  let attributes = filter(a:attributes, '!empty(v:val)')
  let new_highlight = {'name': a:name, 'attrs': attributes}

  call s:Highlight.set(new_highlight, a:options)
endfu

fu! s:get(hightlight_name) abort
  return s:Highlight.get(a:hightlight_name).attrs
endfu

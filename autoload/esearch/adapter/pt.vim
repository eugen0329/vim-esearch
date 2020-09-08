fu! esearch#adapter#pt#new() abort
  return copy(s:Pt)
endfu

let s:Pt = esearch#adapter#base#import()
if exists('g:esearch#adapter#pt#bin')
  " TODO warn deprecated
  let s:Pt.bin = g:esearch#adapter#pt#bin
else
  let s:Pt.bin = 'pt'
endif
if exists('g:esearch#adapter#pt#options')
  " TODO warn deprecated
  let s:Pt.options = g:esearch#adapter#pt#options
else
  let s:Pt.options = '--follow'
endif
let s:Pt.mandatory_options = '--nogroup --nocolor'
" https://github.com/google/re2/wiki/Syntax
call extend(s:Pt, {
      \ 'bool2regex': ['literal', 're2'],
      \ 'regex': {
      \   'literal':   {'icon': '',  'option': ''},
      \   're2':       {'icon': 'r', 'option': '-e'},
      \ },
      \ 'bool2textobj': ['none', 'word'],
      \ 'textobj': {
      \   'none':     {'icon': '',  'option': ''},
      \   'word':     {'icon': 'w', 'option': '--word-regexp'},
      \ },
      \ 'bool2case': ['ignore', 'sensitive'],
      \ 'case': {
      \   'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \   'sensitive': {'icon': 's', 'option': ''},
      \   'smart':     {'icon': 'S', 'option': '--smart-case'},
      \ }
      \})

let s:Pt.filetypes = ''

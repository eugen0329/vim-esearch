fu! esearch#adapter#ack#new() abort
  return copy(s:Ack)
endfu

let s:Ack = esearch#adapter#base#import()
if exists('g:esearch#adapter#ack#bin')
  let s:Ack.bin = g:esearch#adapter#ack#bin
else
  let s:Ack.bin = 'ack'
endif
if exists('g:esearch#adapter#ack#options')
  " TODO warn deprecated
  let s:Ack.options = g:esearch#adapter#ack#options
else
  let s:Ack.options = '--follow'
endif
let s:Ack.mandatory_options = '--nogroup --nocolor --noheading --with-filename --nobreak'
let s:Ack.spec = {
      \   'bool2regex': ['literal', 'pcre'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--literal'},
      \     'pcre':      {'icon': 'r', 'option': ''},
      \   },
      \   'bool2textobj': ['none', 'word'],
      \   'textobj': {
      \     'none':      {'icon': '',  'option': ''},
      \     'word':      {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   'bool2case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--no-smart-case'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Ack.is_success(request) abort
  " later versions behaves like grep (0 - at least one matched line, 1 - no
  " lines matched)
  return a:request.status == 0
endfu

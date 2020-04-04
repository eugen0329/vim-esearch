fu! esearch#adapter#ag#new() abort
  return copy(s:Ag)
endfu

let s:Ag = esearch#adapter#base#import()
if exists('g:esearch#adapter#ag#bin')
  " TODO warn deprecated
  let s:Ag.bin = g:esearch#adapter#ag#bin
else
  let s:Ag.bin = 'ag'
endif
if exists('g:esearch#adapter#ag#options')
  " TODO warn deprecated
  let s:Ag.options = g:esearch#adapter#ag#options
else
  let s:Ag.options = '--follow'
endif
let s:Ag.mandatory_options = '--nogroup --nocolor --noheading'
let s:Ag.spec = {
      \   '_regex': ['literal', 'pcre'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--fixed-strings'},
      \     'pcre':      {'icon': 'r', 'option': ''},
      \   },
      \   '_textobj': ['none', 'word'],
      \   'textobj': {
      \     'none':      {'icon': '',  'option': ''},
      \     'word':      {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   '_case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--case-sensitive'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Ag.is_success(request) abort
  " https://github.com/ggreer/the_silver_searcher/issues/1298
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu

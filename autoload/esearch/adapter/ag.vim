fu! esearch#adapter#ag#new() abort
  return copy(s:Ag)
endfu

let s:Ag = {}
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
      \   '_bound': ['disabled', 'word'],
      \   'bound': {
      \     'disabled':  {'icon': '',  'option': ''},
      \     'word':      {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   '_case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--case-sensitive'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Ag.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.bound[a:esearch.bound].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)
  let context = a:esearch.context > 0 ? '-C ' . a:esearch.context : ''

  return join([self.bin, r, c, w, self.mandatory_options, self.options, context], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! s:Ag.is_success(request) abort
  " https://github.com/ggreer/the_silver_searcher/issues/1298
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu

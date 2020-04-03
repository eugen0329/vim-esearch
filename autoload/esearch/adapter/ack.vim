fu! esearch#adapter#ack#new() abort
  return copy(s:Ack)
endfu

let s:Ack = {}
if exists('g:esearch#adapter#ack#bin')
  let s:Ack.bin = g:esearch#adapter#ack#bin
else
  let s:Ack.bin = 'ack'
endif
if exists('g:esearch#adapter#ack#options')
  " TODO warn deprecated
  let s:Ack.options = g:esearch#adapter#ack#options
else
  let s:Ack.options = ''
endif
let s:Ack.mandatory_options = '--nogroup --nocolor --noheading --with-filename'
let s:Ack.spec = {
      \   '_regex': ['literal', 'pcre'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--literal'},
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
      \     'sensitive': {'icon': 's', 'option': '--no-smart-case'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Ack.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.bound[a:esearch.bound].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return join([self.bin, r, c, w, self.mandatory_options, self.options], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! s:Ack.is_success(request) abort
  " later versions behaves like grep (0 - at least one matched line, 1 - no
  " lines matched)
  return a:request.status == 0
endfu

fu! esearch#adapter#rg#new() abort
  return copy(s:Rg)
endfu

let s:Rg = {}
if exists('g:esearch#adapter#rg#bin')
  " TODO warn deprecated
  let s:Rg.bin = g:esearch#adapter#rg#bin
else
  let s:Rg.bin = 'rg'
endif
if exists('g:esearch#adapter#rg#options')
  " TODO warn deprecated
  let s:Rg.options = g:esearch#adapter#rg#options
else
  " --text: Search binary files as if they were text
  let s:Rg.options = '--text'
endif
let s:Rg.mandatory_options = '--no-heading --color=never --line-number --with-filename'
" https://docs.rs/regex/1.3.6/regex/#syntax
" Crate stands for regexp lib from crete packages registry. Is default as
" pcre is only supported in later versions
let s:Rg.spec = {
      \   '_regex': ['literal', 'crate'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--fixed-strings'},
      \     'crate':     {'icon': 'r', 'option': ''},
      \     'pcre2':     {'icon': 'P', 'option': '--pcre2'},
      \   },
      \   '_bound': ['disabled', 'word'],
      \   'bound': {
      \     'disabled': {'icon': '',  'option': ''},
      \     'word':     {'icon': 'w', 'option': '--word-regexp'},
      \     'line':     {'icon': 'l', 'option': '--line-regexp'},
      \   },
      \   '_case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--case-sensitive'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Rg.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.bound[a:esearch.bound].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return join([self.bin, r, c, w, self.mandatory_options, self.options], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! s:Rg.is_success(request) abort
  " https://github.com/BurntSushi/ripgrep/issues/948
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu

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
if exists('g:esearch#adapter#rg#orgions')
  " TODO warn deprecated
  let s:Rg.orgions = g:esearch#adapter#rg#orgions
else
  " --text: Search binary files as if they were text
  let s:Rg.orgions = '--text'
endif
let s:Rg.mandatory_orgions = '--no-heading --color=never --line-number --with-filename'
let s:Rg.spec = {
      \   'regex': {
      \     'literal':   {'icon': '',  'option': '--fixed-strings'},
      \     'regex':     {'icon': 'r', 'option': ''},
      \     'pcre':      {'icon': 'P', 'option': '--pcre2'},
      \   },
      \   'word': {
      \     'any':       {'icon': '',  'option': ''},
      \     'whole':     {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': '--case-sensitive'},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Rg.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.word[a:esearch.word].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return join([self.bin, r, c, w, self.mandatory_orgions,
        \ self.orgions, a:escape(a:pattern), joined_paths], ' ')
endfu

fu! s:Rg.is_success(request) abort
  " https://github.com/BurntSushi/ripgrep/issues/948
  return a:request.status == 0
        \ || (a:request.status == 1 && empty(a:request.errors) && empty(a:request.data))
endfu

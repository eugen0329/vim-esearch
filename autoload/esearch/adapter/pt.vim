fu! esearch#adapter#pt#new() abort
  return copy(s:Pt)
endfu

let s:Pt = {}
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
let s:Pt.spec = {
      \   'regex': {
      \     'literal':   {'icon': '',  'option': ''},
      \     'regex':     {'icon': 'r', 'option': '-e'},
      \   },
      \   'word': {
      \     'any':       {'icon': '',  'option': ''},
      \     'whole':     {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': ''},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Pt.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.word[a:esearch.word].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return join([self.bin, r, c, w, self.mandatory_options,
        \ self.options, a:escape(a:pattern), joined_paths], ' ')
endfu

fu! s:Pt.is_success(request) abort
  " https://github.com/monochromegane/the_platinum_searcher/issues/150
  return a:request.status == 0
endfu

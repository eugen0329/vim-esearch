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
" https://github.com/google/re2/wiki/Syntax
let s:Pt.spec = {
      \   '_regex': ['literal', 're2'],
      \   'regex': {
      \     'literal':   {'icon': '',  'option': ''},
      \     're2':       {'icon': 'r', 'option': '-e'},
      \   },
      \   '_textobj': ['none', 'word'],
      \   'textobj': {
      \     'none':     {'icon': '',  'option': ''},
      \     'word':     {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   '_case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': ''},
      \     'smart':     {'icon': 'S', 'option': '--smart-case'},
      \   }
      \ }

fu! s:Pt.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.textobj[a:esearch.textobj].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)
  let context = ''
  if a:esearch.after > 0   | let context .= ' -A ' . a:esearch.after   | endif
  if a:esearch.before > 0  | let context .= ' -B ' . a:esearch.before  | endif
  if a:esearch.context > 0 | let context .= ' -C ' . a:esearch.context | endif

  return join([self.bin, r, c, w, self.mandatory_options, self.options, context], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . (empty(joined_paths) ? '.' : joined_paths)
endfu

fu! s:Pt.is_success(request) abort
  " https://github.com/monochromegane/the_platinum_searcher/issues/150
  return a:request.status == 0
endfu

fu! esearch#adapter#pt#new() abort
  return copy(s:Pt)
endfu

let s:Pt = esearch#adapter#base#import()
if exists('g:esearch#adapter#pt#bin')
  call esearch#util#deprecate('g:esearch#adapter#pt#options. Please, use g:esearch.adapters.pt.bin')
  let s:Pt.bin = g:esearch#adapter#pt#bin
else
  let s:Pt.bin = 'pt'
endif
if exists('g:esearch#adapter#pt#options')
  call esearch#util#deprecate('g:esearch#adapter#pt#options. Please, use g:esearch.adapters.pt.options')
  let s:Pt.options = g:esearch#adapter#pt#options
else
  let s:Pt.options = '--follow'
endif
let s:Pt.mandatory_options = '--nogroup --nocolor'
let s:glob = {'icon': '-G', 'opt': '-G '}
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
      \ },
      \ 'globs': [s:glob],
      \ 'str2glob': {'-G': s:glob, '--file-search-regex': s:glob},
      \})

fu! s:Pt.command(esearch) abort dict
  let regex = self.regex[a:esearch.regex].option
  let case = self.textobj[a:esearch.textobj].option
  let textobj = self.case[a:esearch.case].option

  if empty(a:esearch.paths)
    let paths = self.pwd()
  else
    let paths = esearch#shell#join(a:esearch.paths)
  endif

  let context = ''
  if a:esearch.after > 0   | let context .= ' -A ' . a:esearch.after   | endif
  if a:esearch.before > 0  | let context .= ' -B ' . a:esearch.before  | endif
  if a:esearch.context > 0 | let context .= ' -C ' . a:esearch.context | endif

  return join([
        \ self.bin,
        \ regex,
        \ case,
        \ textobj,
        \ self.mandatory_options,
        \ self.options,
        \ context,
        \ self.filetypes2args(a:esearch.filetypes),
        \ a:esearch.globs.arg(),
        \ '--',
        \ a:esearch.pattern.arg,
        \ paths,
        \], ' ')
endfu

fu! s:Pt.pwd() abort dict
  return '.'
endfu

fu! s:Pt.is_success(request) abort
  " https://github.com/monochromegane/the_platinum_searcher/issues/150
  return a:request.status == 0
endfu

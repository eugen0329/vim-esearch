fu! esearch#adapter#git#new() abort
  return copy(s:Git)
endfu

let s:Git = {}
if exists('g:esearch#adapter#git#bin')
  " TODO warn deprecated
  let s:Git.bin = g:esearch#adapter#git#bin
else
  let s:Git.bin = 'git'
endif
if exists('g:esearch#adapter#git#options')
  " TODO warn deprecated
  let s:Git.options = g:esearch#adapter#git#options
else
  " -I: Process a binary file as if it did not contain matching data
  let s:Git.options = '-I '
endif

" -H - show filenames
" -I - don't search binary files
let s:Git.mandatory_options = '-H --no-color --line-number --untracked'
let s:Git.spec = {
      \   '_regex': ['literal', 'perl'],
      \   'regex': {
      \     'literal':  {'icon': '',  'option': '--fixed-strings'},
      \     'basic':    {'icon': 'G', 'option': '--basic-regexp'},
      \     'extended': {'icon': 'E', 'option': '--extended-regexp'},
      \     'perl':     {'icon': 'P', 'option': '--perl-regexp'},
      \   },
      \   'word': {
      \     'any':       {'icon': '',  'option': ''},
      \     'whole':     {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   '_case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': ''},
      \   }
      \ }

fu! s:Git.command(esearch, pattern, escape) abort dict
  let r = self.spec.regex[a:esearch.regex].option
  let c = self.spec.word[a:esearch.word].option
  let w = self.spec.case[a:esearch.case].option

  let joined_paths = esearch#adapter#ag_like#joined_paths(a:esearch)

  return join([self.bin, '--no-pager grep', r, c, w, self.mandatory_options, self.options], ' ')
        \ . ' -- ' .  a:escape(a:pattern) . ' ' . joined_paths
endfu

fu! s:Git.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu

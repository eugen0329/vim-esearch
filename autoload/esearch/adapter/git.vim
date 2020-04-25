fu! esearch#adapter#git#new() abort
  return copy(s:Git)
endfu

let s:Git = esearch#adapter#base#import()
if exists('g:esearch#adapter#git#bin')
  " TODO warn deprecated
  let s:Git.bin = g:esearch#adapter#git#bin
else
  let s:Git.bin = 'git --no-pager grep'
endif
if exists('g:esearch#adapter#git#options')
  " TODO warn deprecated
  let s:Git.options = g:esearch#adapter#git#options
else
  " -I: don't match binary files
  let s:Git.options = '-I '
endif

" -H - show filenames
" -I - don't search binary files
let s:Git.mandatory_options = '-H --no-color --line-number --untracked'
let s:Git.spec = {
      \   'bool2regex': ['literal', 'basic'],
      \   'regex': {
      \     'literal':  {'icon': '',  'option': '--fixed-strings'},
      \     'basic':    {'icon': 'G', 'option': '--basic-regexp'},
      \     'extended': {'icon': 'E', 'option': '--extended-regexp'},
      \     'pcre':     {'icon': 'P', 'option': '--perl-regexp'},
      \   },
      \   'bool2textobj': ['none', 'word'],
      \   'textobj': {
      \     'none':     {'icon': '',  'option': ''},
      \     'word':     {'icon': 'w', 'option': '--word-regexp'},
      \   },
      \   'bool2case': ['ignore', 'sensitive'],
      \   'case': {
      \     'ignore':    {'icon':  '', 'option': '--ignore-case'},
      \     'sensitive': {'icon': 's', 'option': ''},
      \   }
      \ }

let s:Git.spec.filetypes = ''

fu! s:Git.filetypes2args(filetypes) abort dict
  return ''
endfu

fu! s:Git.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu

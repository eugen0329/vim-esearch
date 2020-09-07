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
  " --no-untracked: to avoid errors when .paths = '`git rev-list HEAD`' is used
  let s:Git.options = '-I --no-untracked'
endif

" --or is ommited as it's the default

" -H - show filenames
" -I - don't search binary files
let s:Git.mandatory_options = '-H --no-color --line-number'
call extend(s:Git, {
      \ 'bool2regex': ['literal', 'basic'],
      \ 'regex': {
      \   'literal':  {'icon': '',  'option': '--fixed-strings'},
      \   'basic':    {'icon': 'G', 'option': '--basic-regexp'},
      \   'extended': {'icon': 'E', 'option': '--extended-regexp'},
      \   'pcre':     {'icon': 'P', 'option': '--perl-regexp'},
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
      \ },
      \ 'pattern_kinds': [
      \   {'opt': '-e ',             'regex': 1},
      \   {'opt': '--and -e ',       'regex': 1},
      \   {'opt': '--not -e ',       'regex': 1},
      \   {'opt': '--and --not -e ', 'regex': 1},
      \ ],
      \})

fu! s:Git.command(esearch) abort dict
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
        \ a:esearch.pattern.arg,
        \ '--',
        \ paths,
        \], ' ')
endfu

let s:Git.filetypes = ''

fu! s:Git.filetypes2args(filetypes) abort dict
  return ''
endfu

fu! s:Git.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu

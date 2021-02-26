fu! esearch#adapter#git#new() abort
  return copy(s:Git)
endfu

let s:Git = esearch#adapter#base#import()
if exists('g:esearch#adapter#git#bin')
  call esearch#util#deprecate('g:esearch#adapter#git#options. Please, use g:esearch.adapters.git.bin')
  let s:Git.bin = g:esearch#adapter#git#bin
else
  let s:Git.bin = 'git --no-pager'
endif
if exists('g:esearch#adapter#git#options')
  call esearch#util#deprecate('g:esearch#adapter#git#options. Please, use g:esearch.adapters.git.options')
  let s:Git.options = g:esearch#adapter#git#options
else
  " -I: don't match binary files
  " --no-untracked: to avoid errors when .paths = '`git rev-list HEAD`' is used
  let s:Git.options = '-I --no-untracked'
endif

" -H - show filenames
" -I - don't search binary files
" --or is ommited in pattern kinds as it's the default
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
      \ 'multi_pattern': 1,
      \ 'pattern_kinds': [
      \   {'icon': '',            'opt': '-e ',             'regex': 1},
      \   {'icon': '--and --not', 'opt': '--and --not -e ', 'regex': 0},
      \   {'icon': '--and',       'opt': '--and -e ',       'regex': 1},
      \   {'icon': '--not',       'opt': '--not -e ',       'regex': 0},
      \ ],
      \})

fu! s:Git.command(esearch) abort dict
  let regex = self.regex[a:esearch.regex].option
  let textobj = self.textobj[a:esearch.textobj].option
  let case = self.case[a:esearch.case].option

  let pipe = ''
  if empty(a:esearch.paths)
    let paths = self.pwd()
  elseif type(a:esearch.paths) ==# type({})
    let [pipe, paths] = a:esearch.paths.command(self, a:esearch)
  else
    let paths = esearch#shell#join_pathspec(a:esearch.paths)
  endif

  let context = ''
  if a:esearch.after > 0   | let context .= ' -A ' . a:esearch.after   | endif
  if a:esearch.before > 0  | let context .= ' -B ' . a:esearch.before  | endif
  if a:esearch.context > 0 | let context .= ' -C ' . a:esearch.context | endif

  return join([
        \ pipe,
        \ self.bin,
        \ 'grep',
        \ regex,
        \ case,
        \ textobj,
        \ self.mandatory_options,
        \ self.options,
        \ context,
        \ a:esearch.pattern.arg,
        \ paths,
        \], ' ')
endfu

fu! s:Git.is_success(request) abort
  " 0 if a line is match, 1 if no lines matched, > 1 are for errors
  return a:request.status == 0 || a:request.status == 1
endfu
